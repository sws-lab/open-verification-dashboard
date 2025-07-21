<script lang="ts">
	import { superForm } from 'sveltekit-superforms';
	import { Control, Field, FieldErrors, Label } from 'formsnap';
	import { Button, Icon, Modal, PageSelector } from '$ui';
	import { goto, invalidate } from '$app/navigation';
	import { SvelteSet } from 'svelte/reactivity';
	import Search from '$components/ui/search.svelte';

	let { data } = $props();
	let errorMessage = $state('');
	let statusModal: Modal.StatusModal | null = $state(null);
	let newProofObligationModal: Modal.Modal | null = $state(null);
	let confirmDeleteModal: Modal.ErrorConfirm | null = $state(null);

	let selectedObligations: SvelteSet<number> = new SvelteSet();
	let allSelected = $state(false);
	let selectedCount = $derived(
		allSelected
			? data.proofObligations.proofObligationsCount - selectedObligations.size
			: selectedObligations.size
	);

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
				newProofObligationModal?.close();
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

	const { form: formData, enhance } = form;

	async function compareObligations() {
		if (selectedObligations.size !== 2 || allSelected) {
			statusModal?.error('Please select exactly two proof obligations to compare.');
			return;
		}
		let entries = selectedObligations.entries();
		const entry1 = entries.next().value;
		const entry2 = entries.next().value;
		if (!entry1 || !entry2) {
			statusModal?.error('Could not retrieve selected proof obligations.');
			return;
		}
		const proofObligationId1 = entry1[0];
		const proofObligationId2 = entry2[0];
		try {
			const response = await fetch(`/api/proofObligations/compare`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ proofObligationId1, proofObligationId2 })
			});
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
			const url = `/projects/${data.project.id}/${data.project.revision}/project/${result.id}`;
			goto(url);
		} catch (error) {
			console.error('Error comparing proof obligations:', error);
			statusModal?.error('Failed to compare proof obligations. Please try again.');
			return;
		}
	}

	function onsearch(searchQuery: string) {
		goto(
			`/projects/${data.project.id}/${data.project.revision}/proofObligations?page=1&filter=${encodeURIComponent(searchQuery)}`,
			{ keepFocus: true, replaceState: true }
		);
	}

	function selectObligation(
		id: number,
		event: Event & { currentTarget: EventTarget & HTMLInputElement }
	) {
		const checked = event.currentTarget.checked;
		if ((checked && !allSelected) || (allSelected && !checked)) {
			selectedObligations.add(id);
		} else {
			// eslint-disable-next-line drizzle/enforce-delete-with-where
			selectedObligations.delete(id);
		}
	}

	function selectAll(event: Event & { currentTarget: EventTarget & HTMLInputElement }) {
		const checked = event.currentTarget.checked;
		allSelected = checked;
		selectedObligations.clear();
	}

	function deleteSelectedObligations(confirmed: boolean) {
		if (!confirmed) return;
		fetch('/api/proofObligations', {
			method: 'DELETE',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({
				ids: Array.from(selectedObligations),
				reversed: allSelected
			})
		})
			.then((response) => {
				if (!response.ok) {
					statusModal?.error('Failed to delete proof obligations. Please try again.');
					return;
				} else {
					invalidate('app:proofObligations');
				}
				selectedObligations.clear();
				allSelected = false;
			})
			.catch((error) => {
				console.error('Error deleting proof obligations:', error);
				statusModal?.error('Failed to delete proof obligations. Please try again.');
			});
	}
</script>

<Modal.StatusModal bind:this={statusModal} />
<Modal.ErrorConfirm
	bind:this={confirmDeleteModal}
	title="Delete Proof Obligations"
	onclose={deleteSelectedObligations}
>
	{selectedCount} proof obligations will be deleted.<br />
	Are you sure you want to delete the selected proof obligations?<br />
	This action cannot be undone.<br />
</Modal.ErrorConfirm>

<Modal.Modal title="New Proof Obligation" bind:this={newProofObligationModal}>
	{#snippet content(close)}
		<form method="POST" use:enhance enctype="multipart/form-data">
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

			<Button type="submit" block>Upload Proof Obligation</Button>

			<Button type="secondary" block onclick={close}>Cancel</Button>
		</form>
	{/snippet}
</Modal.Modal>

<div class="proofObligationsView">
	<div class="proofObligationsView__list">
		<h3>
			Proof Obligations - Revision {data.project.revision}
		</h3>
		<div class="proofObligationsView__list__searchNew">
			<Search {onsearch} searchQuery={data.proofObligations.filter} />
			<Button onclick={newProofObligationModal?.open}>New Proof Obligation</Button>
		</div>
		<div class="proofObligationsView__list__content">
			<nav class="proofObligationsView__list__content__actions">
				<input
					type="checkbox"
					id="select-all"
					name="select-all"
					checked={allSelected}
					indeterminate={selectedObligations.size > 0}
					onchange={selectAll}
				/>
				<span>
					{#if selectedObligations.size == 0 && !allSelected}
						{data.proofObligations.proofObligationsCount} proof obligations found
					{:else}
						{selectedCount}/{data.proofObligations.proofObligationsCount} selected
					{/if}
				</span>
				<div class="proofObligationsView__list__content__actions__spacer">&nbsp;</div>
				<Button
					type="error"
					disabled={selectedObligations.size === 0 && !allSelected}
					slim
					onclick={() => confirmDeleteModal?.open()}
				>
					<Icon icon="delete" />
					Delete
				</Button>
				<Button
					type="secondary"
					disabled={selectedObligations.size !== 2}
					slim
					onclick={compareObligations}
				>
					<Icon icon="compare" />
					Compare
				</Button>
			</nav>
			{#if data.proofObligations.proofObligationsCount > 0}
				<ul>
					{#each data.proofObligations.proofObligation as obligation, index (obligation.id)}
						<li class="proofObligationsView__list__content__item">
							<input
								class="proofObligationsView__list__content__item__checkbox"
								type="checkbox"
								id="obligation-{obligation.id}"
								name="obligation-{obligation.id}"
								value={{ id: obligation.id, index }}
								group="obligations"
								checked={selectedObligations.has(obligation.id) || allSelected}
								onchange={(e) => selectObligation(obligation.id, e)}
							/>
							<label for="obligation-{obligation.id}">
								<h4 class="proofObligationsView__list__content__item__header">{obligation.name}</h4>
								<p class="proofObligationsView__list__content__item__date">
									#{obligation.id} Uploaded on {new Date(
										obligation.uploadDate
									).toLocaleDateString()}
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
							</label>
						</li>
					{/each}
				</ul>
			{:else}
				<p class="proofObligationsView__list__content__item__no-items">
					No proof obligations found for this revision.
				</p>
			{/if}
		</div>
		<PageSelector
			href="/projects/{data.project.id}/{data.project.revision}/proofObligations"
			currentPage={data.proofObligations.page}
			totalPages={data.proofObligations.totalPages}
			params={{ filter: data.proofObligations.filter }}
		/>
	</div>
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
		flex-direction: column;
		justify-content: space-around;
		align-items: center;
		flex-wrap: wrap;
		gap: 1rem;

		&__list,
		&__compare {
			background: white;
			border-radius: 0.5rem;
			padding: 1rem;
			width: 60vw;
			@media (max-width: 900px) {
				width: 100%;
			}
		}

		&__list {
			$border-color: gray;
			ul {
				padding: 0;
				margin: 0;
				display: flex;
				flex-direction: column;
			}

			&__searchNew {
				display: grid;
				grid-template-columns: 1fr auto;
				gap: 1rem;
				margin-bottom: 0.3rem;
			}

			&__content {
				border: 1px solid $border-color;
				border-radius: 0.5rem;

				&__actions {
					border-bottom: 1px solid $border-color;
					padding: 0.4rem 1rem;
					display: flex;
					align-items: center;
					gap: 0.5rem;

					&__spacer {
						flex-grow: 1;
					}

					input[type='checkbox'] {
						margin: 0;
					}
				}

				&__item {
					border-top: 1px solid $border-color;
					&:first-child {
						border-top: none;
					}

					display: flex;
					padding: 0.5rem 1.2rem 0.5rem 0rem;
					list-style: none;
					max-width: 100%;
					cursor: pointer;

					label {
						display: grid;
						grid-template-areas:
							'header status'
							'date status';
						grid-template-columns: auto 1fr;
						width: 100%;
						cursor: pointer;
					}

					&__no-items {
						margin: 2rem;
					}

					&__checkbox {
						grid-area: check;
						align-self: center;
						margin: 0rem 1rem;
						cursor: pointer;
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

					&:hover {
						background-color: #f3f3f3;
					}
				}
			}
		}
	}
</style>
