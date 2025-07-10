<script>
	import Icon from "$components/ui/icon.svelte";
	let { data } = $props();
</script>
<section class="head">
	<h2>
		Projects
	</h2>

	<nav class="search">
		<Icon icon="search" size="1.2em"/>
		<input type="text" placeholder="Search" />
	</nav>

	<button>
		New Project
	</button>
</section>

<section class="projects">
	{#if data.errored}
		<p class="error">Error loading projects: {data.message}</p>
	{:else if data.projects.length > 0}
		{#each data.projects as project (project.id)}
			<div class="project">
				<h3>{project.name}</h3>
				<p>{project.description}</p>
				<span class="revision">Revision: {project.revision}</span>
			</div>
		{/each}
	{:else}
		<p class="no-projects">No projects found.</p>
	{/if}
</section>