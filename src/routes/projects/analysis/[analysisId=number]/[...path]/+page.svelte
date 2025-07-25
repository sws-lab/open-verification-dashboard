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

	let conflicts = $derived<ConflictType[]>(
		data.analysis.conflicts.conflicts[`./${data.path}`].sort((a, b) => {
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
					<DropdownSelectItem name="Hello1" label="Hello 1" />
					<DropdownSelectItem name="Hello2" label="Hello 2" />
					<DropdownSelectItem name="Hello3" label="Hello 3" />
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
				<p>No errors found in this file.</p>
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
