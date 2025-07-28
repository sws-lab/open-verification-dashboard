<script lang="ts">
	import AnalyzedFilesTable from '$components/analyzedFilesTable.svelte';
	import { Button, Progress } from '$ui';

	const { data } = $props();

	let totalAgreements = Object.values(data.analysis.stats).reduce(
		(acc, stats) => acc + stats.agreeOnSafe + stats.agreeOnWarning + stats.agreeOnError,
		0
	);
	let totalChecks = Object.values(data.analysis.stats).reduce(
		(acc, stats) => acc + stats.totalSafe + stats.totalWarning + stats.totalError,
		0
	);
</script>

<div class="stats">
	<div class="stats__header">
		<Button
			href="/projects/{data.analysis.projectId}/{data.analysis.revision}/proofObligations"
			type="secondary"
		>
			Back to proof obligations
		</Button>
		<h2>Analyzed files</h2>
	</div>
	<div class="stats__global-stats">
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
		href="/projects/analysis/{data.analysis.id}"
		stats={data.analysis.stats}
	/>
</div>

<style lang="scss">
	.stats {
		overflow-y: scroll;
		max-height: calc(100vh - var(--header-height));
		padding: 1rem;
		padding-top: 0;

		&__header {
			display: flex;
			gap: 1rem;
			background: var(--main-background-color);
			padding: 1rem 0;
			h2 {
				font-size: 2rem;
				flex-grow: 1;
				margin: 0;
			}
		}
	}

	.stats {
		&__global-stats {
			display: flex;
			align-items: center;
			justify-content: center;
			flex-wrap: wrap;
			margin-bottom: 1rem;
			gap: 0.5rem;
		}
	}
</style>
