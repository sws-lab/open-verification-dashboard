<script lang="ts">
	import { Conflict } from '$components';
	import AnalyzedFilesTable from '$components/analyzedFilesTable.svelte';
	import ReadOnlyEditor from '$components/readOnlyEditor.svelte';
	import { Button, Progress } from '$ui';
	import type { Conflict as ConflictType } from '$lib/conflicts/conflict';
	import loadProjectFile from '$lib/utils/fileImport';
	import { Pane, Splitpanes } from 'svelte-splitpanes';

	const { data } = $props();

	let currentFile: null | string = $state(null);
	let content = $state('');
	let editor: ReadOnlyEditor | null = $state(null);
	let loading: boolean = $state(false);
	let error: string | null = $state(null);
	let conflicts = $state<ConflictType[]>([]);

	let totalAgreements = Object.values(data.analysis.stats).reduce(
		(acc, stats) => acc + stats.agreeOnSafe + stats.agreeOnWarning + stats.agreeOnError,
		0
	);
	let totalChecks = Object.values(data.analysis.stats).reduce(
		(acc, stats) => acc + stats.totalSafe + stats.totalWarning + stats.totalError,
		0
	);

	function loadFile(file: string) {
		if (currentFile === file && content !== '') return;

		currentFile = file;
		loading = true;
		loadProjectFile(data.analysis.projectId, data.analysis.revision, file)
			.then((new_content) => {
				if (new_content.type === 'error') {
					error = new_content.content;
					content = '';
				} else if (new_content.type === 'file') {
					content = new_content.content;
					conflicts = data.analysis.conflicts.conflicts[file] || [];
					conflicts.sort((a, b) => {
						if (a.range === b.range) return 0;
						if (a.range.start.line !== b.range.start.line) {
							return a.range.start.line - b.range.start.line;
						}
						return a.range.start.column - b.range.start.column;
					});
					error = null;
				} else {
					error = 'Unknown file type';
					content = '';
				}
				loading = false;
			})
			.catch((err) => {
				console.error(err);
				error = 'Failed to load file';
				loading = false;
			});
	}

	function scrollToRange(index: number) {
		document.querySelector(`#conflict-${index}`)?.scrollIntoView({
			behavior: 'smooth',
			block: 'start'
		});
	}
</script>

<Splitpanes style="height: calc(100vh - var(--header-height))">
	<Pane snapSize={10}>
		<div class="pane">
			{#if loading}
				<p class="centerp">Loading...</p>
			{:else if error !== null}
				<p class="centerp">{error}</p>
			{:else if content === ''}
				<p class="centerp">No file selected</p>
			{/if}
			<ReadOnlyEditor
				bind:this={editor}
				visible={currentFile !== null && !error && content !== ''}
				sources={content}
				diagnostics={conflicts}
				{scrollToRange}
			/>
		</div>
	</Pane>
	<Pane class="pane" snapSize={27}>
		{#if currentFile === null}
			<div class="file pane">
				<h2>Analyzed files</h2>
				<div class="file__global-stats">
					<Progress
						value={totalAgreements}
						max={totalChecks}
						id="total-progress"
						aria-label="Percentage of checks agreed upon by both analysis tools"
					/>
					<label for="total-progress">
						{totalAgreements}/{totalChecks} checks agreed upon
					</label>
				</div>

				<AnalyzedFilesTable
					files={Object.keys(data.analysis.conflicts.conflicts)}
					onFileSelect={loadFile}
					stats={data.analysis.stats}
				/>
			</div>
		{:else}
			<div class="error pane">
				<div class="error__header">
					<Button
						onclick={() => {
							currentFile = null;
							content = '';
							error = null;
							conflicts = [];
						}}
						type="secondary"
					>
						Back to file list
					</Button>
					<h2>Errors of {currentFile}</h2>
				</div>

				{#each conflicts as conflict, index (index)}
					<Conflict
						{conflict}
						po1Name={data.analysis.po1Name}
						po2Name={data.analysis.po2Name}
						onrange={editor?.selectRange}
						id={`conflict-${index}`}
					/>
				{:else}
					<p>No errors found in this file.</p>
				{/each}
			</div>
		{/if}
	</Pane>
</Splitpanes>

<style lang="scss">
	.centerp {
		display: flex;
		justify-content: center;
		align-items: center;
		height: 100%;
		font-size: 1.5rem;
		color: var(--text-color);
	}
	.pane {
		overflow-y: scroll;
		max-height: calc(100vh - var(--header-height));
	}

	.file,
	.error {
		padding: 1rem;
		padding-top: 0;
		h2 {
			font-size: 2rem;
		}
	}

	.file {
		h2 {
			margin: 1rem 0;
		}
		&__global-stats {
			display: flex;
			align-items: center;
			justify-content: center;
			flex-wrap: wrap;
			margin-bottom: 1rem;
		}
	}

	.error {
		&__header {
			h2 {
				margin: 0;
				flex-grow: 1;
			}
			display: flex;
			gap: 1rem;
			position: sticky;
			top: 0;
			background: var(--main-background-color);
			padding: 1rem 0;
		}
	}
</style>
