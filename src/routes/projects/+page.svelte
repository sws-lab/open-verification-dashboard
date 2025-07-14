<script lang="ts">
	import { goto } from "$app/navigation";
	import PageSelector from "$components/ui/pageSelector.svelte";
	import { Button, Project } from "$ui";
	let { data } = $props();

	let searchQuery = $state(data.filter);
	let searchTimeout: NodeJS.Timeout | null = null;

	function search() {
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
	{:else if data.projects.length > 0}
		<div class="projects__list">
			{#each data.projects as project (project.id)}
				<Project {project} />
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