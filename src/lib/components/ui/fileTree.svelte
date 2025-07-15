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
		  };

	let { baseUrl, onFileClick }: FileTreeProps = $props();

	let rootFile: file | null = $state(null);

	function load(filePath: string): Promise<file> {
		return fetch(`${baseUrl}/${filePath}`)
			.then((response) => response.json())
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
			});
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
	<li class={file.type}>
		{#if file.type === 'directory'}
			<button onclick={() => loadFolderContent(file)}>
				{file.name}
			</button>
			<ul class={file.type} class:opened={file.opened}>
				{#if file.opened}
					{#each file.files as childFile}
						{@render file_element(childFile, `${path}/${childFile.name}`)}
					{:else}
						<li>Loading...</li>
					{/each}
				{/if}
			</ul>
		{:else}
			<button onclick={() => onFileClick && onFileClick(path)}>
				{file.name}
			</button>
		{/if}
	</li>
{/snippet}

<ul class="file-tree">
	{#if rootFile}
		{@render file_element(rootFile, '')}
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
				border-left: 1px solid gray;
			}
		}

		li {
			button {
				display: flex;
				align-items: center;
				gap: 0.5rem;
				margin: 0;
				padding: 0;
				font-size: 1rem;
			}
			&.directory button {
				&::before {
					@include icon-content('folder');
				}
			}
			&.file button {
				&::before {
					@include icon-content('description');
				}
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
