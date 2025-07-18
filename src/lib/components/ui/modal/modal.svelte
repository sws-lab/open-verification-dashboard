<script lang="ts">
	import { type Snippet } from 'svelte';

	interface ModalProps {
		title?: string;
		content: Snippet<[close: (returnValue?: any) => void]>;
		onclose?: (returnValue?: any) => void;
	}

	let { title = 'Modal', content, onclose }: ModalProps = $props();

	let dialog: HTMLDialogElement | null = $state(null);

	export function close(data?: any) {
		dialog?.close(data);
	}

	export function open() {
		dialog?.showModal();
	}

	function oncloseProxy(event: Event & { returnValue: any }) {
		if (event.returnValue) {
			onclose?.(dialog?.returnValue);
		} else {
			onclose?.(null);
		}
	}
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
