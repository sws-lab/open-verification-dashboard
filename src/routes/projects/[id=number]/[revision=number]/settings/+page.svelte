<script lang="ts">
	import { goto, invalidate } from '$app/navigation';
	import { Button, Modal } from '$ui';
	import type { ActionResult } from '@sveltejs/kit';
	import { Control, Field, FieldErrors, Label } from 'formsnap';
	import { superForm } from 'sveltekit-superforms';

	const { data } = $props();

	let settingsError = $state('');
	let setSettingsError = (message: string) => {
		settingsError = message;
	};
	let revisionError = $state('');
	let setRevisionError = (message: string) => {
		revisionError = message;
	};

	let statusModal: Modal.StatusModal | null = $state(null);
	let errorConfirm: Modal.ErrorConfirm | null = $state(null);

	function onError(
		error: {
			result: {
				type: 'error';
				status?: number;
				error:
					| App.Error
					| Error
					| {
							message: string;
					  };
			};
		},
		errorMessage: (err: string) => void
	) {
		console.error('Form error:', error);
		errorMessage('An unexpected error occurred. Please try again.');
	}

	function onResult(
		form: {
			result: ActionResult;
			formEl: HTMLFormElement;
			formElement: HTMLFormElement;
			cancel: () => void;
		},
		errorMessage: (err: string) => void,
		onSuccess: () => void
	) {
		if (form.result.type == 'failure') {
			console.error('Form failure:', form.result);
			if (form.result.data?.error) {
				errorMessage(`Error ${form.result.status}: ${form.result.data.error}`);
			} else {
				errorMessage('');
			}
		} else if (form.result.type == 'success') {
			errorMessage('');
			onSuccess();
		}
	}

	const editForm = superForm(data.editForm, {
		taintedMessage: true,
		onError: (error) => onError(error, setSettingsError),
		onResult: (form) =>
			onResult(form, setSettingsError, () => {
				invalidate('app:project');
				statusModal?.success('Project settings updated successfully.');
			}),
		resetForm: false
	});
	const { form: editFormData, enhance: editEnhance } = editForm;
	const revisionForm = superForm(data.newRevisionForm, {
		taintedMessage: true,
		onError: (error) => onError(error, setRevisionError),
		onResult: (form) =>
			onResult(form, setRevisionError, () => {
				// Handle successful revision upload
			})
	});
	const { form: revisionFormData, enhance: revisionEnhance } = revisionForm;

	async function onErrorConfirmClose(confirmed: boolean) {
		if (!confirmed) return;

		const result = await fetch('/api/projects', {
			method: 'DELETE',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({ projectId: data.project.id })
		});
		if (result.status === 204) {
			statusModal?.info('Project deleted successfully.');
			goto('/projects');
		} else {
			const error = await result.json();
			console.error('Failed to delete project:', error);
			statusModal?.error(`Failed to delete project: ${error.error}`);
		}
	}
</script>

<Modal.StatusModal bind:this={statusModal} id="settings-status-modal" />
<Modal.ErrorConfirm
	title="Project deletion"
	bind:this={errorConfirm}
	onclose={onErrorConfirmClose}
	id="delete-project-confirm"
>
	<p>Are you sure you want to delete this project? This action is irreversible.</p>
</Modal.ErrorConfirm>

<section class="settings">
	<h2>Edit project</h2>
	<p>Modify project name and description.</p>
	<form method="POST" use:editEnhance enctype="multipart/form-data" action="?/edit">
		{#if settingsError}
			<p class="global-errors">
				{settingsError}
			</p>
		{/if}
		<Field name="name" form={editForm}>
			<Control>
				{#snippet children({ props })}
					<Label>Project Name</Label>
					<input
						type="text"
						placeholder="Project Name"
						{...props}
						bind:value={$editFormData.name}
					/>
				{/snippet}
			</Control>
			<FieldErrors />
		</Field>
		<Field name="description" form={editForm}>
			<Control>
				{#snippet children({ props })}
					<Label>Project Description</Label>
					<textarea
						placeholder="Project Description"
						{...props}
						bind:value={$editFormData.description}
					></textarea>
				{/snippet}
			</Control>
			<FieldErrors />
		</Field>
		<Button type="submit" block>Save Changes</Button>
	</form>
</section>

<section class="settings">
	<h2>Project Revision</h2>
	<p>Upload a new revision for the project.</p>
	<form method="POST" use:revisionEnhance enctype="multipart/form-data" action="?/revision">
		{#if revisionError}
			<p class="global-errors">
				{revisionError}
			</p>
		{/if}
		<input type="hidden" name="id" value={data.project.id} />
		<input type="hidden" name="revision" value={data.project.revision} />
		<Field name="sources" form={revisionForm}>
			<Control>
				{#snippet children({ props })}
					<Label>Sources</Label>
					<input
						type="file"
						accept=".zip,.tar,.tar.gz"
						{...props}
						bind:value={$revisionFormData.sources}
					/>
				{/snippet}
			</Control>
			<FieldErrors />
		</Field>
		<Button type="submit" block>Upload New Revision</Button>
	</form>
</section>

<section class="settings">
	<h2>Delete Project</h2>
	<p class="margin-bot">This action is irreversible and will permanently delete the project.</p>
	<Button type="error" onclick={() => errorConfirm?.open()}>Delete Project</Button>
</section>

<style lang="scss">
	.global-errors {
		color: red;
		margin: 0;
		text-align: center;
	}

	section {
		margin: 0 auto;
		padding: 1rem;
		margin-top: 1rem;

		&:first-of-type {
			margin-top: 2.5rem;
		}

		border-radius: 0.5rem;
		background: white;

		display: flex;
		flex-direction: column;

		width: 30vw;
		min-width: 500px;
		@media (max-width: 800px) {
			width: 80vw;
		}
		@media (max-width: 500px) {
			min-width: 0;
			width: 100%;
		}

		> h2 {
			margin-bottom: 0.5rem;
			font-size: 1.25rem;
			margin: 0;
			text-align: center;
		}

		> p {
			margin: 0;
			text-align: center;
			font-size: 0.875rem;

			&.margin-bot {
				margin-bottom: 1rem;
			}
		}
	}
</style>
