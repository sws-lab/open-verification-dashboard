<script lang="ts">
	import { onMount } from 'svelte';

	interface FileTreeProps {
		baseUrl: string;
		onFileClick?: (filePath: string) => void;
	}

	type file =
		| {
				name: string;
				type: 'directory';
				loaded: boolean;
				opened: boolean;
				files: Array<file>;
		  }
		| {
				name: string;
				type: 'file';
		  }
		| {
			name: string;
			type: 'error';
			error: string;
		};

	let { baseUrl, onFileClick }: FileTreeProps = $props();

	let rootFile: file | null = $state(null);

	function load(filePath: string): Promise<file> {
		return fetch(`${baseUrl}/${filePath}`)
			.then((response) => {
				if (response.status !== 200) {
					throw new Error(`Failed to load file: ${response.statusText}`);
				}
				return response.json()
			})
			.then((data) => {
				if (data.type === 'directory') {
					data.files = data.files.map((child: any) => ({
						...child,
						opened: false,
						loaded: false
					}));
					data.loaded = true;
					data.opened = true;
				}
				return data;
			}).catch((error) => {
				return {
					name: filePath,
					type: 'error',
					error: error.message
				}
			})
	}

	function loadFolderContent(file: file) {
		if (file.type !== 'directory') return;
		if (!file.loaded) {
			file.opened = true;
			load(file.name).then((data) => {
				if (data.type === 'directory') {
					file.files = data.files;
					file.loaded = true;
				}
			});
		} else {
			file.opened = !file.opened;
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
	<li class={file.type} class:opened={file.type === "directory" && file.opened}>
		{#if file.type === 'directory'}
			<button onclick={() => loadFolderContent(file)}>
				{file.name}
			</button>
			<ul class={file.type}>
				{#if file.opened}
					{#if file.loaded}
						{#each file.files as childFile}
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
			<button onclick={() => onFileClick && onFileClick(path)}>
				{file.name}
			</button>
		{/if}
	</li>
{/snippet}

<ul class="file-tree">
	{#if rootFile && rootFile.type === 'directory' && rootFile.loaded}
		{#each rootFile.files as file}
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
				background: linear-gradient($color, $color) no-repeat .65rem/1px 100%;
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
			}
			&.directory button {
				&::before {
					@include icon-content('chevron_right', $size: 1.7rem);
				}
			}
			&.directory.opened > button {
				&::before {
					@include icon-content('expand_more', $size: 1.7rem);
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
