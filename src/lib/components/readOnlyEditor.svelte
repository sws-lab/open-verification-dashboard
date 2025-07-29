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
	import { linter, lintGutter, type Diagnostic } from '@codemirror/lint';
	import {
		conflictMessage,
		conflictSeverity,
		conflictCategory,
		type Conflict
	} from '$lib/conflicts/conflict';
	import type { range } from '$lib/conflicts/range';

	interface Props {
		visible?: boolean;
		sources?: string;
		diagnostics?: Conflict[];
		scrollToRange?: (range: number) => void;
	}

	let {
		visible = true,
		sources = '',
		diagnostics = [],
		scrollToRange = () => {}
	}: Props = $props();

	let view: EditorView | null = $state(null);
	let needsRefresh = $state(false);

	function lineColumnToPos(line: number, column: number, view: EditorView): number {
		let pos = view.state.doc.line(line).from + column;
		return pos;
	}

	export function setSourceFile(sourceFile: string) {
		view?.dispatch({
			changes: {
				from: 0,
				to: view.state.doc.length,
				insert: sourceFile
			}
		});
	}

	export function selectRange(range: range) {
		view?.dispatch({
			selection: {
				anchor: lineColumnToPos(range.start.line, range.start.column, view),
				head: lineColumnToPos(range.end.line, range.end.column, view)
			},
			scrollIntoView: true
		});
		view?.focus();
	}

	const errorDisplay = linter(
		(view: EditorView) =>
			diagnostics.map((conflict: Conflict, index: number): Diagnostic => {
				needsRefresh = false;
				return {
					from: lineColumnToPos(conflict.range.start.line, conflict.range.start.column, view),
					to: lineColumnToPos(conflict.range.end.line, conflict.range.end.column, view),
					severity: conflictSeverity(conflict.kind),
					message: conflictMessage(conflict),
					source: conflictCategory(conflict),
					markClass:
						conflict.kind === 'OnlyOneProofObligation'
							? 'cm-kind-OnlyOneProofObligation'
							: `cm-kind-${conflict.kind} cm-kind-multiple`,
					actions: [
						{
							name: 'Details',
							apply: () => {
								console.log('Action clicked for conflict', index);
								scrollToRange(index);
							}
						}
					]
				};
			}),
		{
			needsRefresh: () => needsRefresh,
			autoPanel: false
		}
	);

	$effect(() => {
		if (diagnostics !== null) {
			console.log('Refreshing diagnostics');
			needsRefresh = true;
			setTimeout(() => view?.dispatch(), 0);
		}
	});
	$effect(() => {
		if (view && sources) {
			view.dispatch({
				changes: {
					from: 0,
					to: view.state.doc.length,
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
		view = e.detail;
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
		lintGutter(),
		errorDisplay
	]}
/>

<style lang="scss">
	:global(.hidden) {
		display: none;
	}

	:global(.cm-editor) {
		font-size: 1.1rem;
	}

	:global(.cm-kind-OnlyOneProofObligation:not([class*='cm-kind-multiple'])) {
		background-color: #c1c1c1;
	}
</style>
