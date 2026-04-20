<script lang="ts">
	import { Modal } from '.';
	import { Button } from '..';

	let title = $state('Info');
	let displayedText = $state('Nothing to display');
	let modal = $state<Modal | null>(null);

	let { id } = $props();

	export function info(text: string) {
		title = 'Info';
		displayedText = text;
		modal?.open();
	}

	export function error(text: string) {
		title = 'Error';
		displayedText = text;
		modal?.open();
	}

	export function success(text: string) {
		title = 'Success';
		displayedText = text;
		modal?.open();
	}

	export function warning(text: string) {
		title = 'Warning';
		displayedText = text;
		modal?.open();
	}

	export function custom(title: string, text: string) {
		title = title;
		displayedText = text;
		modal?.open();
	}

	export function close() {
		modal?.close();
	}
</script>

<Modal {title} bind:this={modal} {id}>
	{#snippet content(close)}
		<p>{displayedText}</p>
		<nav class="actions">
			<Button type="main" onclick={() => close()} autofocus>Close</Button>
		</nav>
	{/snippet}
</Modal>

<style lang="scss">
	.actions {
		display: flex;
		justify-content: end;
		gap: 1rem;
		margin-top: 1rem;
	}

	p {
		margin: 0;
	}
</style>
