<script lang="ts">
	import { onMount } from 'svelte';

	interface FileTreeProps {
		baseUrl: string;
		onFileClick?: (filePath: string) => void;
	}

	type file = (
		| {
				name: string;
				type: 'directory';
				loaded: boolean;
				opened: boolean;
				files: Array<file>;
				focusNode?: HTMLButtonElement;
		  }
		| {
				name: string;
				type: 'file';
				focusNode?: HTMLButtonElement;
		  }
		| {
				name: string;
				type: 'error';
				error: string;
		  }
	) & {
		parent?: () => file;
		previous?: () => file;
		next?: () => file;
	};

	let { baseUrl, onFileClick }: FileTreeProps = $props();

	let rootFile: file | null = $state(null);
	let selected: file | null = $state(null);
	let aheadString: string = '';
	let lastKeyPressTime: number = 0;

	function load(filePath: string): Promise<file> {
		return fetch(`${baseUrl}/${filePath}`)
			.then((response) => {
				if (response.status !== 200) {
					throw new Error(`Failed to load file: ${response.statusText}`);
				}
				return response.json();
			})
			.then((data: file) => {
				return data;
			})
			.catch((error) => {
				return {
					name: filePath,
					type: 'error',
					error: error.message
				};
			});
	}

	function filePath(file: file): string {
		if (file.type === 'error') return '';
		let path = file.name;
		while (file.parent && file.parent().name) {
			file = file.parent();
			path = file.name + '/' + path;
		}
		return path;
	}

	function loadFolderContent(file: file) {
		if (file.type !== 'directory') return;
		if (!file.loaded) {
			file.opened = true;
			load(filePath(file)).then((data) => {
				if (data.type === 'directory') {
					file.files = data.files.sort((a, b) =>
						a.type === 'directory' && b.type === 'file'
							? -1
							: a.type === 'file' && b.type === 'directory'
								? 1
								: a.name.localeCompare(b.name)
					);
					file.loaded = true;
					for (let i = 0; i < file.files.length; i++) {
						const childFile = file.files[i];
						childFile.parent = () => file;
						if (i > 0) {
							childFile.previous = () => file.files[i - 1];
							childFile.next = undefined;
							file.files[i - 1].next = () => childFile;
						}
						if (childFile.type === 'directory') {
							childFile.opened = false;
							childFile.loaded = false;
						}
					}
				}
			});
		} else {
			file.opened = !file.opened;
		}
	}

	function fileClick(file: file, filePath: string) {
		selected = file;
		onFileClick?.(filePath);
	}

	function lastFocusableFile(file: file) {
		if (file.type === 'file') {
			return file.focusNode;
		} else if (file.type === 'directory') {
			if (file.opened && file.files.length > 0) {
				return lastFocusableFile(file.files[file.files.length - 1]);
			} else {
				return file.focusNode;
			}
		} else {
			return null;
		}
	}

	function getNextFocusable(file: file, subfolder: boolean = true) {
		if (file.type === 'directory' && file.opened && file.files.length > 0 && subfolder) {
			if (file.files[0].type !== 'error') {
				return file.files[0].focusNode;
			} else {
				return null;
			}
		} else if (file.next) {
			const next = file.next();
			if (next.type !== 'error') {
				console.log('next focusable', next.focusNode);
				return next.focusNode;
			} else {
				return null;
			}
		} else if (file.parent) {
			return getNextFocusable(file.parent(), false);
		}
		return null;
	}

	function getPreviousFocusable(file: file) {
		const previous = file.previous?.();
		const parent = file.parent?.();
		if (previous) {
			return lastFocusableFile(previous);
		} else if (parent && parent.type !== 'error') {
			console.log('previous focusable', parent.focusNode);
			return parent.focusNode;
		}
		return null;
	}

	function findNextStartingWith(file: file, sequence: string): HTMLButtonElement | undefined {
		let currentFile: file | undefined;
		if (file.type === 'directory' && file.opened && file.files.length > 0) {
			currentFile = file.files[0];
		} else {
			currentFile = file.next?.() || file.parent?.();
		}
		if (!currentFile) {
			return undefined;
		}
		while (currentFile !== file && !currentFile.name.toLocaleLowerCase().startsWith(sequence)) {
			console.log('currentFile', currentFile.name);
			if (currentFile.type === 'directory' && currentFile.opened) {
				currentFile = currentFile.files[0];
			} else if (currentFile.next) {
				currentFile = currentFile.next();
			} else if (currentFile.parent && currentFile.parent().name) {
				currentFile = currentFile.parent();
			} else {
				break;
			}
		}
		if (currentFile.type !== 'error' && currentFile.name.toLocaleLowerCase().startsWith(sequence)) {
			return currentFile.focusNode;
		}
	}

	function onKeyDown(event: KeyboardEvent, file: file) {
		const parent = file.parent?.();
		if (event.key === 'ArrowLeft') {
			if (file.type === 'directory' && file.opened) {
				file.opened = false;
			} else if (parent && parent.type !== 'error') {
				parent.focusNode?.focus();
			}
		} else if (event.key === 'ArrowRight') {
			if (file.type === 'directory') {
				if (!file.loaded) {
					loadFolderContent(file);
				}
				if (!file.opened) {
					file.opened = true;
				} else if (file.files[0]?.type !== 'error') {
					file.files[0].focusNode?.focus();
				}
			}
		} else if (event.key === 'Home') {
			if (rootFile && rootFile.type === 'directory' && rootFile.files[0]?.type !== 'error') {
				rootFile.files[0].focusNode?.focus();
			}
		} else if (event.key === 'End') {
			if (rootFile && rootFile.type !== 'error') {
				lastFocusableFile(rootFile)?.focus();
			}
		} else if (event.key === 'ArrowDown') {
			getNextFocusable(file)?.focus();
		} else if (event.key === 'ArrowUp') {
			getPreviousFocusable(file)?.focus();
		} else if (event.key.length == 1 && event.key.match(/^[a-zA-Z0-9]$/)) {
			const currentTime = Date.now();
			if (currentTime - lastKeyPressTime > 500) {
				aheadString = '';
			}
			lastKeyPressTime = currentTime;
			aheadString += event.key.toLowerCase();
			console.log('aheadString', aheadString);
			findNextStartingWith(file, aheadString)?.focus();
		}
	}

	onMount(() => {
		load('').then((data) => {
			rootFile = data;
			if (rootFile.type === 'directory') {
				rootFile.loaded = true;
				rootFile.opened = true; // Open the root directory by default
			}
		});
	});
</script>

{#snippet file_element(file: file, path: string)}
	<li class={file.type} class:opened={file.type === 'directory' && file.opened}>
		{#if file.type === 'directory'}
			<button
				onclick={() => loadFolderContent(file)}
				role="treeitem"
				aria-expanded={file.opened}
				aria-selected={selected === file}
				aria-owns="folder-{path}"
				aria-controls="folder-{path}"
				id="button-{path}"
				onkeydown={(event) => onKeyDown(event, file)}
				class:selected={selected === file}
				bind:this={file.focusNode}
			>
				{file.name}
			</button>
			<ul class={file.type} id="folder-{path}" aria-label="Folder: {path}" role="group">
				{#if file.opened}
					{#if file.loaded}
						{#each file.files as childFile, index (index)}
							{@render file_element(childFile, `${path}/${childFile.name}`)}
						{/each}
					{:else}
						<li>Loading...</li>
					{/if}
				{/if}
			</ul>
		{:else if file.type === 'error'}
			<div class="error">
				{file.error}
			</div>
		{:else}
			<button
				onclick={() => fileClick(file, path)}
				role="treeitem"
				aria-selected={selected === file}
				id="file-{path}"
				class:selected={selected === file}
				aria-label="File: {path}"
				onkeydown={(event) => onKeyDown(event, file)}
				bind:this={file.focusNode}
			>
				{file.name}
			</button>
		{/if}
	</li>
{/snippet}

<ul class="file-tree" role="tree" aria-label="File Tree">
	{#if rootFile && rootFile.type === 'directory' && rootFile.loaded}
		{#each rootFile.files as file, index (index)}
			{@render file_element(file, file.type === 'directory' ? file.name : '')}
		{/each}
	{:else}
		<li>Loading...</li>
	{/if}
</ul>

<style lang="scss">
	@use '$styles/mixins.scss' as *;
	ul {
		list-style: none;
	}

	.file-tree {
		margin: 0;
		padding: 0;

		ul {
			padding-left: 1rem;
			&.directory {
				$color: #b3b3b3d7;
				background: linear-gradient($color, $color) no-repeat 0.4rem/1px 100%;
			}
		}

		li {
			button {
				display: flex;
				align-items: center;
				gap: 0.1rem;
				margin: 0;
				padding: 0;
				font-size: 1rem;

				&.selected {
					font-weight: bold;
				}
			}
			&.directory > button {
				&::before {
					@include icon-content('chevron_right', $size: 1.5rem);
					margin-left: -0.3rem;
					margin-right: -0.2rem;
				}
			}
			&.directory.opened > button {
				&::before {
					@include icon-content('expand_more', $size: 1.5rem);
				}
			}
			&.file button {
				&::before {
					@include icon-content('description');
				}
			}

			&.error {
				color: var(--error-color);
				font-weight: bold;
				margin: 0.5rem 0;
			}
		}
	}

	li {
		margin: 0.25rem 0;
	}

	button {
		background: none;
		border: none;
		cursor: pointer;
	}
</style>
