<script lang="ts">
	import type { EditorView } from "codemirror";
	import CodeMirror from "svelte-codemirror-editor";
	import {
		indentOnInput, syntaxHighlighting, defaultHighlightStyle,
		bracketMatching, foldGutter,
	} from "@codemirror/language"
	import { lineNumbers } from "@codemirror/view";
	import {cpp} from "@codemirror/lang-cpp"
	import { FileTree } from "$ui";

	let { data } = $props();

	let editor: EditorView | null = $state(null);

	async function onFileSelected(file: string) {
		console.log("Selected file:", file);
		await fetch(`/api/projects/${data.project.id}/${data.project.revision}/${file}`)
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
	<nav class="project-view__tree">
		<h3>Project files</h3>
		<FileTree
			baseUrl={`/api/projects/${data.project.id}/${data.project.revision}`}
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