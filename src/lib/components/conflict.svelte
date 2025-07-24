<script lang="ts">
	import { conflictCategory, conflictMessage, type Conflict } from '$lib/conflicts/conflict';
	import type { check } from '$lib/conflicts/check';
	import type { range } from '$lib/conflicts/range';
	import { Button } from './ui';

	interface Props {
		conflict: Conflict;
		po1Name: string;
		po2Name: string;
		id: string;
		onrange?: (range: range) => void;
	}

	let { conflict, po1Name, po2Name, onrange = () => {}, id }: Props = $props();

	function toTitleCase(str: string): string {
		return str.replace(/([A-Z])/g, ' $1');
	}

	function* zip<T>(arr1: T[], arr2: T[]): Generator<[T | null, T | null]> {
		const length = Math.max(arr1.length, arr2.length);
		for (let i = 0; i < length; i++) {
			if (i < arr1.length && i < arr2.length) {
				yield [arr1[i], arr2[i]];
			} else if (i < arr1.length) {
				yield [arr1[i], null];
			} else if (i < arr2.length) {
				yield [null, arr2[i]];
			}
		}
	}
</script>

{#snippet detail(check: check | null, left: boolean)}
	{#if check}
		<div
			class="check {check.kind}"
			class:left
			aria-label="Check {check.kind} at {check.range.start.line}.{check.range.start.column} - {check
				.range.end.line}.{check.range.end.column} for {left ? po1Name : po2Name}"
		>
			<h5 class="check__kind">{check.kind}</h5>
			<Button type="link" italic onclick={() => onrange?.(check.range)}>
				{check.range.start.line}.{check.range.start.column}-{check.range.end.line}.{check.range.end
					.column}
			</Button>
			<p class="check__message" aria-label="Check message">
				{#if check.messages}
					{check.messages}
				{:else}
					No message
				{/if}
			</p>
		</div>
	{/if}
{/snippet}

<div class="conflict" {id}>
	<h3>
		{conflictCategory(conflict)}:
		<Button type="link" italic onclick={() => onrange?.(conflict.range)}>
			{conflict.range.start.line}.{conflict.range.start.column}-{conflict.range.end.line}.{conflict
				.range.end.column}
		</Button>
	</h3>
	<p class="conflict__description">
		{toTitleCase(conflict.kind)}: {conflictMessage(conflict)}
	</p>
	<div class="conflict__details">
		<h4 class="conflict__details__name-left">{po1Name}</h4>
		<h4 class="conflict__details__name-right">{po2Name}</h4>

		{#each zip(conflict.from_po1, conflict.from_po2) as [po1Check, po2Check], index (index)}
			{#if !po1Check && index === 0}
				<p>No checks for this range</p>
			{/if}
			{#if !po2Check && index === 0}
				<p>No checks for this range</p>
			{/if}
			{@render detail(po1Check, true)}
			{@render detail(po2Check, false)}
		{:else}
			<p>No checks for this range</p>
			<p>No checks for this range</p>
		{/each}
	</div>
</div>

<style lang="scss">
	.conflict {
		background: white;
		border: 1px solid var(--border-color);
		border-radius: 0.5rem;
		margin: 0.5rem 0;
		padding: 1rem;

		h3 {
			margin: 0;
			width: 100%;
			text-align: left;
		}

		&__description {
			margin: 0.5rem 0;
			font-size: 1rem;
		}

		&__details {
			display: grid;
			grid-template-columns: 1fr 1fr;
			grid-template-areas:
				'po1Name   po2Name'
				'po1Detail po2Detail';
			gap: 1rem;

			&__name-left,
			&__name-right {
				width: 100%;
				text-align: center;
				margin: 0;
				text-transform: uppercase;
				font-weight: bold;
				font-size: 1.2rem;
			}

			&__name-left {
				grid-area: po1Name;
			}

			&__name-right {
				grid-area: po2Name;
			}

			.check {
				display: grid;
				grid-template-areas:
					'kind range'
					'message message';

				grid-template-columns: auto 1fr;
				grid-template-rows: auto auto;
				margin: 0.5rem 0;
				padding: 0.5rem;
				align-items: center;
				border-radius: 0.25rem;

				grid-column: 2;
				&.left {
					grid-column: 1;
				}

				&.error {
					border-left: 4px solid red;
					background: rgba(255, 0, 0, 0.1);
				}

				&.warning {
					border-left: 4px solid orange;
					background: rgba(255, 165, 0, 0.1);
				}

				&.safe {
					border-left: 4px solid green;
					background: rgba(0, 128, 0, 0.1);
				}

				&__kind {
					grid-area: kind;
					font-weight: bold;
					margin: 0;
					font-size: 1.2rem;
					margin-right: 0.5rem;
					text-transform: capitalize;
				}
				&__message {
					grid-area: message;
					margin: 0;
					margin-top: 0.1rem;
					align-self: start;
					justify-self: start;
					text-wrap: break-word;
				}
			}
		}
	}
</style>
