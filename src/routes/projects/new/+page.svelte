<script lang="ts">
	import { superForm } from 'sveltekit-superforms';
	import { Control, Field, FieldErrors, Label } from 'formsnap';
	import { Button } from '$ui';
	import { goto } from '$app/navigation';

	let { data } = $props();
	let errorMessage = $state('');

	const form = superForm(data.form, {
		onResult: (form) => {
			if (form.result.type == 'failure') {
				console.error(form.result);
				if (form.result.data?.error) {
					errorMessage = `Error ${form.result.status}: ${form.result.data.error}`;
				} else {
					errorMessage = '';
				}
			} else if (form.result.type == 'success') {
				const id = form.result.data?.form.message.id;
				if (!id) {
					goto('/projects');
					return;
				}
				const new_url = `/projects/${id}/0/code`;
				console.log('Redirecting to:', new_url);
				goto(new_url);
			}
		},
		onError: (error) => {
			console.error('Form error:', error);
			errorMessage = 'An unexpected error occurred. Please try again.';
		}
	});
	const { form: formData, enhance } = form;
</script>

<form method="POST" enctype="multipart/form-data" use:enhance>
	<h2>New Project</h2>
	{#if errorMessage}
		<p class="global-errors">
			{errorMessage}
		</p>
	{/if}
	<Field name="name" {form}>
		<Control>
			{#snippet children({ props })}
				<Label>Project Name</Label>
				<input type="text" placeholder="Project Name" {...props} bind:value={$formData.name} />
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Field name="description" {form}>
		<Control>
			{#snippet children({ props })}
				<Label>Project Description</Label>
				<textarea placeholder="Project Description" {...props} bind:value={$formData.description}
				></textarea>
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Field name="sources" {form}>
		<Control>
			{#snippet children({ props })}
				<Label class="a">Sources</Label>
				<input type="file" accept=".zip,.tar,.tar.gz" {...props} bind:value={$formData.sources} />
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Button type="submit" center>Create Project</Button>
	<Button type="secondary" href="/projects" center>Cancel</Button>
</form>

<style lang="scss">
	form {
		background: white;

		margin: 2rem auto;
		padding: 1.5rem 3rem;
		border-radius: 0.5rem;

		width: 30vw;
		min-width: 500px;
		@media (max-width: 800px) {
			width: 80vw;
		}
		@media (max-width: 500px) {
			min-width: 0;
			width: 100%;
		}

		display: flex;
		flex-direction: column;

		h2 {
			margin-top: 0;
			text-align: center;
		}

		.global-errors {
			color: red;
			margin: 0;
			text-align: center;
		}
	}
</style>
