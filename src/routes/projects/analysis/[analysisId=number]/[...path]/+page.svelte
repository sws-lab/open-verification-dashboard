<script lang="ts">
	import { Conflict } from '$components';
	import ReadOnlyEditor from '$components/readOnlyEditor.svelte';
	import { Button, Icon } from '$ui';
	import type { Conflict as ConflictType } from '$lib/conflicts/conflict';
	import { Pane, Splitpanes } from 'svelte-splitpanes';
	import Dropdown from '$components/ui/dropdown/dropdown.svelte';
	import DropdownSelectItem from '$components/ui/dropdown/dropdownSelectItem.svelte';

	const { data } = $props();

	let editor: ReadOnlyEditor | null = $state(null);
	let filterDropdown: Dropdown | null = $state(null);

	let filterOptions = $state({
		NoConflictSafe: false,
		NoConflictWarning: false,
		NoConflictError: false,
		Unchecked: false,
		OnlyOneProofObligation: true,
		SafetyW1: true,
		SafetyW2: true,
		PrecisionW1: true,
		PrecisionW2: true,
		ErrorLevel: true
	});

	let conflicts = $derived<ConflictType[]>(
		data.analysis.conflicts.conflicts[`./${data.path}`]
			.filter((element) => {
				switch (element.kind) {
					case 'NoConflictSafe':
						return filterOptions.NoConflictSafe;
					case 'NoConflictWarning':
						return filterOptions.NoConflictWarning;
					case 'NoConflictError':
						return filterOptions.NoConflictError;
					case 'Unchecked':
						return filterOptions.Unchecked;
					case 'OnlyOneProofObligation':
						return filterOptions.OnlyOneProofObligation;
					case 'SafetyW1':
						return filterOptions.SafetyW1;
					case 'SafetyW2':
						return filterOptions.SafetyW2;
					case 'PrecisionW1':
						return filterOptions.PrecisionW1;
					case 'PrecisionW2':
						return filterOptions.PrecisionW2;
					default:
						return true; // Default case to include all other types
				}
			})
			.sort((a, b) => {
				if (a.range === b.range) return 0;
				if (a.range.start.line !== b.range.start.line) {
					return a.range.start.line - b.range.start.line;
				}
				return a.range.start.column - b.range.start.column;
			})
	);

	function scrollToRange(index: number) {
		document.querySelector(`#conflict-${index}`)?.scrollIntoView({
			behavior: 'smooth',
			block: 'start'
		});
	}
</script>

<Splitpanes style="height: calc(100vh - var(--header-height))">
	<Pane snapSize={10}>
		<ReadOnlyEditor
			bind:this={editor}
			sources={data.fileContent}
			diagnostics={conflicts}
			{scrollToRange}
		/>
	</Pane>
	<Pane snapSize={27}>
		<div class="error">
			<div class="error__header">
				<Button href="/projects/analysis/{data.analysis.id}" type="secondary">
					Back to file list
				</Button>
				<button
					aria-label="Select shown errors"
					role="combobox"
					aria-expanded="false"
					aria-controls="filter-dropdown"
					onclick={(event) => filterDropdown?.show(event)}
					class="filter-button"
				>
					Filter errors
					<Icon icon="arrow_drop_down" size="2rem" />
				</button>
				<Dropdown bind:this={filterDropdown} id="filter-dropdown" type="combobox">
					<DropdownSelectItem
						name="noConflictSafe"
						label="No Conflict Safe"
						bind:checked={filterOptions.NoConflictSafe}
					/>
					<DropdownSelectItem
						name="noConflictWarning"
						label="No Conflict Warning"
						bind:checked={filterOptions.NoConflictWarning}
					/>
					<DropdownSelectItem
						name="noConflictError"
						label="No Conflict Error"
						bind:checked={filterOptions.NoConflictError}
					/>
					<DropdownSelectItem
						name="unchecked"
						label="Unchecked"
						bind:checked={filterOptions.Unchecked}
					/>
					<DropdownSelectItem
						name="onlyOneProofObligation"
						label="Only One Proof Obligation"
						bind:checked={filterOptions.OnlyOneProofObligation}
					/>
					<DropdownSelectItem
						name="safetyW1"
						label="Safety W1"
						bind:checked={filterOptions.SafetyW1}
					/>
					<DropdownSelectItem
						name="safetyW2"
						label="Safety W2"
						bind:checked={filterOptions.SafetyW2}
					/>
					<DropdownSelectItem
						name="precisionW1"
						label="Precision W1"
						bind:checked={filterOptions.PrecisionW1}
					/>
					<DropdownSelectItem
						name="precisionW2"
						label="Precision W2"
						bind:checked={filterOptions.PrecisionW2}
					/>
				</Dropdown>
				<h2>{data.path}</h2>
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
				<p class="error__message">No errors found in this file.</p>
			{/each}
		</div>
	</Pane>
</Splitpanes>

<style lang="scss">
	.error {
		overflow-y: scroll;
		max-height: calc(100vh - var(--header-height));
		padding: 1rem;
		padding-top: 0;
		height: 100%;

		&__header {
			display: flex;
			gap: 1rem;
			background: var(--main-background-color);
			padding: 1rem 0;
			position: sticky;
			top: 0;
			flex-wrap: wrap;
			h2 {
				font-size: 2rem;
				flex-grow: 1;
				margin: 0;
			}
		}

		&__message {
			height: 100%;
		}
	}

	.filter-button {
		display: flex;
		align-items: center;
		gap: 0.1rem;
		font-size: 1rem;
		padding: 0rem 0rem 0rem 0.6rem;
		cursor: pointer;
		background: var(--main-background-color);
		border: none;
		color: var(--text-color);
		transition: background-color 0.2s ease-in-out;
		&:hover {
			background: var(--main-background-color-hover);
		}
	}
</style>
