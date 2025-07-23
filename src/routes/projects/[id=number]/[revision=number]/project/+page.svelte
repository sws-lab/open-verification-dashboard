<script lang="ts">
	import { FileTree } from '$ui';
	import ReadOnlyEditor from '$components/readOnlyEditor.svelte';
	import loadProjectFile from '$lib/utils/fileImport.js';

	let { data } = $props();
	let editor: ReadOnlyEditor | null = $state(null);

	function loadFile(file: string) {
		loadProjectFile(data.project.id, data.project.revision, file)
			.then((fileContent) => {
				editor?.setSourceFile(fileContent.content || 'No content available');
			})
			.catch((err) => {
				console.error('Failed to load file:', err);
				editor?.setSourceFile('Error loading file');
			});
	}
</script>

<div class="project-view">
	<nav class="project-view__tree">
		<h3>Project files</h3>
		<FileTree
			baseUrl={`/api/projects/${data.project.id}/${data.project.revision}`}
			onFileClick={loadFile}
		/>
	</nav>
	<div class="project-view__editor">
		<ReadOnlyEditor bind:this={editor} />
	</div>
</div>

<style lang="scss">
	.project-view {
		display: grid;
		grid-template-columns: auto 1fr;
		height: 100%;

		&__tree {
			background-color: #f0f0f0;
			border-right: 1px solid #ccc;
			padding: 1rem;
			overflow: auto;
			height: 100%;
			min-height: 0;

			h3 {
				margin: 0;
			}
		}

		&__editor {
			background-color: var(--color-background);
			padding: 1rem;
			border-left: 1px solid var(--color-border);
			height: 100%;
			min-height: 0;
			overflow: auto;
		}
	}
</style>
