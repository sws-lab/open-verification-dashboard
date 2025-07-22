<script lang="ts">
	import { goto, invalidate } from '$app/navigation';
	import PageSelector from '$components/ui/pageSelector.svelte';
	import { Button, Modal, Project, Search } from '$ui';
	let { data } = $props();

	let searchQuery = $state(data.filter);
	let errorConfirmModal: Modal.ErrorConfirm | null = $state(null);
	let statusModal: Modal.StatusModal | null = $state(null);

	let selectedProjectId: number | null = $state(null);

	function search(searchQuery: string) {
		goto(`/projects/?page=${data.page}&filter=${encodeURIComponent(searchQuery)}`, {
			keepFocus: true,
			replaceState: true
		});
	}

	function onaction(action: string, projectId: number) {
		selectedProjectId = projectId;
		if (action === 'delete') {
			errorConfirmModal?.open();
			return;
		} else {
			statusModal?.info('This action is not implemented yet.');
		}
	}

	async function oncloseConfirmModal(shoudlDelete: boolean) {
		if (selectedProjectId == null || !shoudlDelete) return;

		let savedProjectId = selectedProjectId;
		selectedProjectId = null;
		const result = await fetch('/api/projects', {
			method: 'DELETE',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({ projectId: savedProjectId })
		});
		if (result.status === 204) {
			statusModal?.info('Project deleted successfully.');
			invalidate('app:projects');
		} else {
			const error = await result.json();
			console.error('Failed to delete project:', error);
			statusModal?.error(`Failed to delete project: ${error.error}`);
		}
	}
</script>

<section class="head">
	<h2>Projects</h2>
	<div class="search">
		<Search {searchQuery} onsearch={search} />
	</div>
	<Button type="main" href="/projects/new">New Project</Button>
</section>

<section class="projects">
	{#if data.errored}
		<p class="no-elements error">Error loading projects: {data.message}</p>
	{:else if data.projects.length > 0}
		<div class="projects__list">
			{#each data.projects as project (project.id)}
				<Project {project} {onaction} />
			{/each}
		</div>
		<PageSelector
			label="Project pagination"
			href="/projects"
			currentPage={data.page}
			totalPages={data.totalPages}
			params={{ filter: searchQuery }}
		/>
	{:else}
		<p class="no-elements">No projects found.</p>
	{/if}
</section>

<Modal.ErrorConfirm
	title="Are you sure?"
	onclose={oncloseConfirmModal}
	bind:this={errorConfirmModal}
>
	Deleting a project is irreversible. This action will remove all associated data.
</Modal.ErrorConfirm>
<Modal.StatusModal bind:this={statusModal} />

<style lang="scss">
	@use '$styles/mixins.scss' as *;

	section {
		padding: 0 max(3rem, 5vw);
		margin: 0;
	}

	.head {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
		background: white;
		position: relative;
		z-index: 101;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

		h2 {
			font-size: 1.5rem;
		}

		.search {
			width: max(200px, 30vw);
		}
	}

	.projects {
		&__list {
			width: 100%;
			display: grid;
			grid-template-columns: repeat(auto-fill, 250px);
			gap: 1rem;

			@media (max-width: 650px) {
				display: flex;
				flex-direction: column;
				align-items: center;
			}
		}

		.no-elements {
			text-align: center;
			margin-top: 2rem;
			font-size: 1.5rem;

			&.error {
				color: red;
			}
		}
	}
</style>
