<script lang="ts">
	import { superForm } from 'sveltekit-superforms';
	import { Control, Field, FieldErrors, Label } from 'formsnap';
	import { Button, Icon, Modal } from '$ui';
	import { goto, invalidate } from '$app/navigation';

	let { data } = $props();
	let errorMessage = $state('');
	let statusModal: Modal.StatusModal | null = $state(null);
	let selectedObligations: {id: number, index: number}[] = $state([]);
	$inspect(selectedObligations)

	const form = superForm(data.form, {
		onResult: (form) => {
			if (form.result.type == 'failure') {
				console.error(form.result);
				if (form.result.data?.error) {
					errorMessage = `Error ${form.result.status}: ${form.result.data.error}`;
					if (form.result.data.issues) {
						errorMessage += '\nCheck issues in the console for more details.';
					}
					console.error('Form issues:', form.result.data.issues);
				} else {
					errorMessage = '';
				}
			} else if (form.result.type == 'success') {
				statusModal?.success('Analysis uploaded successfully!');
				errorMessage = '';
				invalidate('app:proofObligations');
			}
		},
		onError: (error) => {
			console.error('Form error:', error);
			errorMessage = 'An unexpected error occurred. Please try again.';
		}
	});

	const { form: formData, enhance, message } = form;

	async function compareObligations() {
		if (selectedObligations.length !== 2) {
			statusModal?.error('Please select exactly two proof obligations to compare.');
			return;
		}
		const proofObligationId1 = selectedObligations[0].id;
		const proofObligationId2 = selectedObligations[1].id;
		try {
			const response = await fetch(`/api/proofObligations/compare`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ proofObligationId1, proofObligationId2 })
			})
			if (!response.ok) {
				if (response.body) {
					const errorData = await response.json();
					console.error('Error comparing proof obligations:', errorData);
					statusModal?.error(`Failed to compare proof obligations: ${errorData.error}`);
				} else {
					console.error('Error comparing proof obligations: No response body');
					statusModal?.error('Failed to compare proof obligations. Please try again.');
				}
				return;
			}
			const result = await response.json();
			const url = `/projects/${data.project.id}/${data.project.revision}/code/${result.id}`
			goto(url);
		} catch (error) {
			console.error('Error comparing proof obligations:', error);
			statusModal?.error('Failed to compare proof obligations. Please try again.');
			return;
		}
	}
</script>

<Modal.StatusModal bind:this={statusModal} />
<div class="proofObligationsView">
	<div class="proofObligationsView__list">
		<h3>
			Proof Obligations - Revision {data.project.revision}
		</h3>
		<div class="proofObligationsView__list__content">
			<nav class="proofObligationsView__list__content__actions">
				TODO
			</nav>
			{#if data.proofObligations.proofObligation.length > 0}
				<ul>
					{#each data.proofObligations.proofObligation as obligation, index}
						<li class="proofObligationsView__list__content__item">
							<input
								class="proofObligationsView__list__content__item__checkbox"
								type="checkbox"
								id="obligation-{obligation.id}"
								name="obligation-{obligation.id}"
								value={{id: obligation.id, index}}
								bind:group={selectedObligations}
							/>
							<h4 class="proofObligationsView__list__content__item__header">{obligation.name}</h4>
							<p class="proofObligationsView__list__content__item__date">
								Uploaded on {new Date(obligation.uploadDate).toLocaleDateString()}
							</p>
							<div class="proofObligationsView__list__content__item__status">
								<div class="proofObligationsView__list__content__item__status__icon safe">
									<Icon icon="verified" /> <span>{obligation.safe}</span>
								</div>
								<div class="proofObligationsView__list__content__item__status__icon warning">
									<Icon icon="warning" /> <span>{obligation.warning}</span>
								</div>
								<div class="proofObligationsView__list__content__item__status__icon error">
									<Icon icon="error" /> <span>{obligation.error}</span>
								</div>
							</div>
						</li>
					{/each}
				</ul>
			{:else}
				<p>No proof obligations found for this revision.</p>
			{/if}
		</div>
	</div>

	<div class="proofObligationsView__compare">
		<h3>Compare two Proof Obligations</h3>
		{#if selectedObligations.length < 2}
			<p>Please select two proof obligations to compare.</p>
		{:else if selectedObligations.length > 2}
			<p>You can only compare two proof obligations at a time.</p>
		{:else}
			<p>Comparing:</p>
			<ul>
				{#each selectedObligations as obligation}
					<li>
						{data.proofObligations.proofObligation[obligation.index].name}
					</li>
				{/each}
			</ul>
			<Button onclick={compareObligations}>
				Compare
			</Button>
		{/if}

	</div>

	<form method="POST" use:enhance enctype="multipart/form-data" class="proofObligationsView__form">
		<h3>New Proof Obligation</h3>
		{#if errorMessage}
			<p class="global-errors">
				{errorMessage}
			</p>
		{/if}
		<Field name="name" {form}>
			<Control>
				{#snippet children({ props })}
					<Label>New Analysis Name</Label>
					<input
						type="text"
						placeholder="New Analysis Name"
						{...props}
						bind:value={$formData.name}
					/>
				{/snippet}
			</Control>
			<FieldErrors />
		</Field>

		<Field name="proofObligation" {form}>
			<Control>
				{#snippet children({ props })}
					<Label>Upload Proof Obligation File</Label>
					<input type="file" accept=".json" {...props} bind:value={$formData.proofObligation} />
				{/snippet}
			</Control>
			<FieldErrors />
		</Field>

		<Button type="submit">Upload Proof Obligation</Button>
	</form>
</div>

<style lang="scss">
	.global-errors {
		color: var(--error-color);
		font-weight: bold;
		margin-bottom: 1rem;
	}

	.proofObligationsView {
		padding: 1rem;
		display: flex;
		flex-direction: row;
		justify-content: space-around;
		flex-wrap: wrap;
		gap: 1rem;

		&__list,
		&__form,
		&__compare {
			background: white;
			border-radius: 0.5rem;
			padding: 1rem;
		}

		&__list {
			$border-color: gray;
			ul {
				padding: 0;
				margin: 0;
				display: flex;
				flex-direction: column;
			}
			&__content {
				border: 1px solid $border-color;
				border-radius: 0.5rem;
				&__actions {
					border-bottom: 1px solid $border-color;
					padding: 0.5rem 1rem;
				}

				&__item {
					border-top: 1px solid $border-color;
					&:first-child {
						border-top: none;
					}
					padding: 0.5rem 1.2rem 0.5rem 0rem;
					list-style: none;
					display: grid;
					grid-template-areas:
						'check header status'
						'check date status';
					grid-template-columns: auto auto 1fr;
					max-width: 400px;
					width: 400px;

					&__checkbox {
						grid-area: check;
						align-self: center;
						margin: 0rem 1rem ;
					}

					&__header {
						grid-area: header;
						margin: 0;
						align-self: end;
					}
					&__date {
						grid-area: date;
						font-size: 0.9rem;
						margin: 0;
						color: var(--text-secondary-color);
						align-self: start;
					}
					&__status {
						grid-area: status;
						display: flex;
						flex-direction: row;
						gap: 1rem;
						justify-self: end;

						&__icon {
							display: flex;
							align-items: center;
							gap: 0.1rem;

							&.safe {
								color: var(--safe-color);
							}
							&.warning {
								color: var(--warning-color);
							}
							&.error {
								color: var(--error-color);
							}
						}
					}
				}
			}
		}
	}
</style>
