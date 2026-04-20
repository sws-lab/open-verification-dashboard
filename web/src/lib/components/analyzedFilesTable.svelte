<script lang="ts">
	import type { Stats } from '$lib/conflicts/stats';
	import { Button, Progress } from './ui';

	interface Props {
		files: string[];
		href: string;
		stats: Stats;
	}

	let { files, href, stats }: Props = $props();
	let maxSafeDigits = $derived(
		Object.values(stats).reduce((max, fileStats) => {
			return Math.max(
				max,
				Math.log10(fileStats.totalSafe) + 1,
				Math.log10(fileStats.agreeOnSafe) + 1
			);
		}, 0)
	);
	let maxWarningDigits = $derived(
		Object.values(stats).reduce((max, fileStats) => {
			return Math.max(
				max,
				Math.log10(fileStats.totalWarning) + 1,
				Math.log10(fileStats.agreeOnWarning) + 1
			);
		}, 0)
	);
	let maxErrorDigits = $derived(
		Object.values(stats).reduce((max, fileStats) => {
			return Math.max(
				max,
				Math.log10(fileStats.totalError) + 1,
				Math.log10(fileStats.agreeOnError) + 1
			);
		}, 0)
	);
	let maxDisagreementDigits = $derived(
		Object.values(stats).reduce((max, fileStats) => {
			return Math.max(max, Math.log10(fileStats.disagreement) + 1);
		}, 0)
	);
	let maxOnlyOneCheckedDigits = $derived(
		Object.values(stats).reduce((max, fileStats) => {
			return Math.max(max, Math.log10(fileStats.onlyOneChecked) + 1);
		}, 0)
	);
</script>

{#snippet tdProgress(maxDigits: number, value: number, max: number, file: string)}
	<td class:na={max === 0} class:number={max > 0} class="progress">
		{#if max > 0}
			<div class="progress__content">
				<div class="progress__content__progressBar">
					<Progress
						{value}
						{max}
						id="{file}-progress"
						aria-label="Agreement on checks for file {file}"
					/>
				</div>
				<label for="{file}-progress">
					{String(value).padStart(maxDigits, '0')}/{String(max).padStart(maxDigits, '0')}
				</label>
			</div>
		{:else}
			<span>—</span>
		{/if}
	</td>
{/snippet}

<table>
	<thead>
		<tr>
			<th>File</th>
			<th>Safe</th>
			<th>Warning</th>
			<th>Error</th>
			<th>Disagreements</th>
			<th>Only one</th>
		</tr>
	</thead>
	<tbody>
		{#each files as file (file)}
			<tr>
				<td>
					<Button type="link" italic href="{href}/{file}">{file}</Button>
				</td>
				{@render tdProgress(maxSafeDigits, stats[file].agreeOnSafe, stats[file].totalSafe, file)}
				{@render tdProgress(
					maxWarningDigits,
					stats[file].agreeOnWarning,
					stats[file].totalWarning,
					file
				)}
				{@render tdProgress(maxErrorDigits, stats[file].agreeOnError, stats[file].totalError, file)}
				<td>{String(stats[file].disagreement).padStart(maxDisagreementDigits, '0')}</td>
				<td>{String(stats[file].onlyOneChecked).padStart(maxOnlyOneCheckedDigits, '0')}</td>
			</tr>
		{/each}
	</tbody>
</table>

<style lang="scss">
	table {
		width: 100%;
		border-collapse: collapse;

		thead {
			position: sticky;
			top: 0;
		}

		th,
		td {
			padding: 1rem 1.5rem;
			border-bottom: 1px solid lightgray;
			text-align: center;
		}

		th {
			background-color: #f9f9f9;
			border-bottom: 2px solid darkgray;
			font-weight: bold;
		}

		tr:last-of-type {
			border-bottom: 2px solid darkgray;
		}

		td {
			&.na {
				color: gray;
			}

			&.number {
				font-family: 'Fira Code Variable', monospace;
			}

			&:first-of-type {
				text-align: left;
			}

			label {
				align-self: right;
			}

			.progress__content {
				display: flex;
				justify-content: center;
				align-items: center;
				gap: 1.5rem;

				&__progressBar {
					align-self: left;
					width: 90%;
				}
			}
		}
	}
</style>
