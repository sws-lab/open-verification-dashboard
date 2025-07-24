<script lang="ts">
	import { type Snippet } from 'svelte';
	import { pushState } from '$app/navigation';
	import { page } from '$app/state';

	interface ModalProps {
		title?: string;
		content: Snippet<[close: (returnValue?: string) => void]>;
		onclose?: (returnValue?: string) => void;
		id: string;
	}

	let { title = 'Modal', content, onclose, id }: ModalProps = $props();

	let dialog: HTMLDialogElement | null = $state(null);

	export function close(data?: string) {
		if (dialog) {
			dialog.close(data);
			history.back();
		}
	}

	export function open() {
		dialog?.showModal();
		if (page.state[id]) return;
		pushState('', {
			[id]: true
		});
	}

	function oncloseProxy(event: Event & { currentTarget: HTMLDialogElement }) {
		if (event.returnValue) {
			onclose?.(dialog?.returnValue);
		} else {
			onclose?.();
		}
	}

	$effect(() => {
		if (!page.state[id]) {
			dialog?.close();
		} else {
			dialog?.showModal();
		}
	});
</script>

<dialog bind:this={dialog} class="modal" onclose={oncloseProxy}>
	<h2>{title}</h2>
	<div>
		{@render content(close)}
	</div>
</dialog>

<style lang="scss">
	.modal {
		border: 1px solid lightgray;
		border-radius: 8px;
		padding: 0.5rem 1rem;

		h2 {
			margin: 0;
			font-size: 2rem;
			margin-bottom: 1rem;
			border-bottom: 1px solid #ccc;
		}
	}
</style>
