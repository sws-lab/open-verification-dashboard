<script>
	import { Button } from "$ui";
	let { data } = $props();
</script>
<section class="head">
	<h2>
		Projects
	</h2>

	<nav class="search">
		<input type="text" placeholder="Filter" />
	</nav>

	<Button type="main">
		New Project
	</Button>
</section>

<section class="projects">
	{#if data.errored}
		<p class="no-elements error">Error loading projects: {data.message}</p>
	{:else if data.projects.length > 0}
		{#each data.projects as project (project.id)}
			<div class="project">
				<h3>{project.name}</h3>
				<p>{project.description}</p>
				<span class="revision">Revision: {project.revision}</span>
			</div>
		{/each}
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