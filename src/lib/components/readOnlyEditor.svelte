<script lang="ts">
	import type { EditorView } from 'codemirror';
	import CodeMirror from 'svelte-codemirror-editor';
	import {
		indentOnInput,
		syntaxHighlighting,
		defaultHighlightStyle,
		bracketMatching,
		foldGutter
	} from '@codemirror/language';
	import { lineNumbers } from '@codemirror/view';
	import { cpp } from '@codemirror/lang-cpp';

	let { visible = true, sources = '' } = $props();

	let editor: EditorView | null = $state(null);

	export function setSourceFile(sourceFile: string) {
		editor?.dispatch({
			changes: {
				from: 0,
				to: editor.state.doc.length,
				insert: sourceFile
			}
		});
	}

	$effect(() => {
		if (editor && sources) {
			editor.dispatch({
				changes: {
					from: 0,
					to: editor.state.doc.length,
					insert: sources
				}
			});
		}
	});
</script>

<CodeMirror
	class={visible ? '' : 'hidden'}
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
		cpp()
	]}
/>

<style lang="scss">
	:global(.hidden) {
		display: none;
	}
</style>
