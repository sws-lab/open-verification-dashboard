<script lang="ts">
	import FileTree from "$components/ui/fileTree.svelte";
	import type { EditorView } from "codemirror";
	import CodeMirror from "svelte-codemirror-editor";
	import {
		indentOnInput, syntaxHighlighting, defaultHighlightStyle,
		bracketMatching, foldGutter,
	} from "@codemirror/language"
	import { lineNumbers } from "@codemirror/view";
	import {cpp} from "@codemirror/lang-cpp"

	let { data } = $props();

	let editor: EditorView | null = $state(null);

	async function onFileSelected(file: string) {
		console.log("Selected file:", file);
		await fetch(`/api/projects/${data.project.id}/${data.revision}/${file}`)
			.then(response => response.json())
			.then(content => {
				console.log("File content loaded", content);
				file = content.content || "No content available.";
			})
			.catch(error => {
				console.error("Error loading file:", error);
				file = "Error loading file content.";
			});
		editor?.dispatch({
			changes: {
				from: 0,
				to: editor.state.doc.length,
				insert: file
			}
		})
	}

</script>

<div class="project-view">
	<div class="project-view__header">
		<h2>{data.project.name} <span>#{data.project.id}</span></h2>
	</div>
	<nav class="project-view__tree">
		<h3>Project files</h3>
		<FileTree
			baseUrl={`/api/projects/${data.project.id}/${data.revision}`}
			onFileClick={onFileSelected}
			/>
	</nav>
	<div class="project-view__editor">
		<CodeMirror
			tabSize={4}
			on:ready={(e: CustomEvent<EditorView>) => {
				editor = e.detail;
			}}
			readonly={true}
			basic={false}
			extensions={[
				indentOnInput(),
				bracketMatching(),
				foldGutter(),
				lineNumbers(),
				syntaxHighlighting(defaultHighlightStyle),
				cpp(),
			]}
		/>
	</div>
</div>

<style lang="scss">
	:global(body) {
		height: 100vh;
		max-height: 100vh;
	}

	.project-view {
		display: grid;
		grid-template-areas:
			"header header"
			"tree editor";
		grid-template-columns: auto 1fr;
		grid-template-rows: auto minmax(0, 1fr);
		min-width: 0;
		min-height: 0;
		max-height: 90%;


		&__header {
			grid-area: header;
			background-color: white;
			padding: 1rem;
			font-size: 1.5rem;
			z-index: 101;
			box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
			h2 {
				margin: 0;
				span {
					font-size: 1.27rem;
					color: var(--color-secondary-text);
				}
			}
		}

		&__tree {
			grid-area: tree;
			background-color: white;
			padding: 1rem;
			overflow: auto;
			border-right: 1px solid var(--color-border);
			height: 100%;
			min-height: 0;

			h3 {
				margin: 0;
			}
		}

		&__editor {
			grid-area: editor;
			background-color: var(--color-background);
			padding: 1rem;
			border-left: 1px solid var(--color-border);
			height: 100%;
			min-height: 0;
			overflow: auto;
		}
	}
</style>