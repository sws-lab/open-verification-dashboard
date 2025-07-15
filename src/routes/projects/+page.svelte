<script lang="ts">
	import { goto } from "$app/navigation";
	import PageSelector from "$components/ui/pageSelector.svelte";
	import { Button, Modal, Project } from "$ui";
	let { data } = $props();
	let projects = $state(data.projects);

	let searchQuery = $state(data.filter);
	let searchTimeout: NodeJS.Timeout | null = null;
	let errorConfirmModal: Modal.ErrorConfirm | null = $state(null);
	let statusModal: Modal.StatusModal | null = $state(null);

	let selectedProjectId: number | null = $state(null);


	function search() {
		if (searchQuery.length > 100) {
			searchQuery = searchQuery.slice(0, 100);
		}
		if (searchTimeout) {
			clearTimeout(searchTimeout);
		}
		searchTimeout = setTimeout(() => {
			goto(
				`/projects/?page=${data.page}&filter=${encodeURIComponent(searchQuery)}`,
				{
					keepFocus: true,
					replaceState: true
				}
			);
		}, 300);
	}

	function onaction(action: string, projectId: number) {
		selectedProjectId = projectId;
		if (action === "delete") {
			errorConfirmModal?.open();
			return;
		} else {
			statusModal?.info("This action is not implemented yet.");
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
		})
		if (result.status === 204) {
			statusModal?.info("Project deleted successfully.");
			data.lastPageCount--;
			if (data.lastPageCount === 0) {
				data.totalPages--;
				data.lastPageCount = 30;
			}
			projects = projects.filter(p => p.id !== savedProjectId);
		} else {
			const error = await result.json();
			console.error("Failed to delete project:", error);
			statusModal?.error(`Failed to delete project: ${error.error}`);
		}
	}
</script>
<section class="head">
	<h2>
		Projects
	</h2>

	<nav class="search">
		<input 
			type="text"
			placeholder="Filter" 
			bind:value={searchQuery} 
			oninput={search}/>
	</nav>

	<Button type="main" href="/projects/new">
		New Project
	</Button>
</section>

<section class="projects">
	{#if data.errored}
		<p class="no-elements error">Error loading projects: {data.message}</p>
	{:else if projects.length > 0}
		<div class="projects__list">
			{#each projects as project (project.id)}
				<Project {project} onaction={onaction} />
			{/each}
		</div>
		<PageSelector
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
@use "$styles/mixins.scss" as *;

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
		display: flex;
		align-items: center;
		padding: 0.3rem 0.6rem;
		border: 1px solid #ccc;
		border-radius: 4px;
		width: max(200px, 30vw);
		input {
			width: 100%;
			border: none;
			outline: none;
			font-size: 1rem;
			margin-left: 0.5rem;
		}
		&::before {
			@include icon-content('search', $size: 1.5rem);
		}
	}
}

.projects {

	&__list {
		width: 100%;
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: 1rem;
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