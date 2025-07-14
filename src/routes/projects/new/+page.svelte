<script lang="ts">
	import { superForm } from "sveltekit-superforms";
	import { Control, Field, FieldErrors, Label } from "formsnap";
	import { Button } from "$ui";
	import { goto } from "$app/navigation";


 
	let { data } = $props();
	let errorMessage = $state("");
 
	const form = superForm(data.form, {
		onResult: (form) => {
			if (form.result.type == 'failure') {
				console.error(form.result);
				if (form.result.data?.error) {
					errorMessage = `Error ${form.result.status}: ${form.result.data.error}`;
				} else {
					errorMessage = ''
				}				
			} else if (form.result.type == 'success') {
				const id = form.result.data?.form.message.id;
				if (!id) {
					goto('/projects');
					return;
				}
				const new_url = `/projects/${id}/0`;
				console.log("Redirecting to:", new_url);
				goto(new_url, {
					replaceState: true,
					noScroll: true
				});
			}
		},
		onError: (error) => {
			console.error("Form error:", error);
			errorMessage = "An unexpected error occurred. Please try again.";
		}
	});
	const { form: formData, enhance, message } = form;
</script>

<form method="POST" enctype="multipart/form-data" use:enhance>
	<h2>
		New Project
	</h2>
	{#if errorMessage}
		<p class="global-errors">
			{errorMessage}
		</p>
	{/if}
	<Field name="name" {form}>
		<Control>
			{#snippet children({ props })}
				<Label>
					Project Name
				</Label>
				<input type="text" placeholder="Project Name" {...props} />
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Field name="description" {form}>
		<Control>
			{#snippet children({ props })}
				<Label>
					Project Description
				</Label>
				<textarea placeholder="Project Description" {...props}></textarea>
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Field name="sources" {form}>
		<Control>
			{#snippet children({ props })}
				<Label class="a">
					Sources
				</Label>
				<input type="file" accept=".zip,.tar,.tar.gz" {...props} />
			{/snippet}
		</Control>
		<FieldErrors />
	</Field>
	<Button type="submit" center>
		Create Project
	</Button>
	<Button type="secondary" href="/projects" center>
		Cancel
	</Button>
</form>

	
<style lang="scss">
	form {
		background: white;

		margin: 2rem auto;
		padding: 1.5rem 3rem;
		border-radius: 0.5rem;

		width: 30vw;

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

		:global([data-fs-field]) {
			font-weight: bold;
			width: 100%;
		}
		
		:global([data-fs-control]) {
			width: 100%;
			padding: 0.3rem 0.6rem;
			border: 1px solid #ccc;
			border-radius: 4px;
			box-sizing: border-box;
		}

		:global([data-fs-label]) {
			display: block;
			font-weight: bold;
			margin-bottom: 0.1rem;
			margin-top: 1rem;
			font-size: 1.2rem;
		}

		:global([data-fs-error]) {
			color: var(--error-color);
		}

		:global(input[type="text"][data-fs-error]) {
			color: inherit;
			border-color: var(--error-color);
			box-shadow: 0 0 2px 1px var(--error-color);
		}

		:global([data-fs-label][data-fs-error]) {
			color: inherit;
		}

		:global(button) {
			margin-top: 1rem;
			margin-bottom: .7rem;
		}

		textarea {
			resize: vertical;
			min-height: 100px;
		}
	}

</style>