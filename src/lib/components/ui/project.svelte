<script lang="ts">
	import Icon from './icon.svelte';

	type project = {
		id: number;
		name: string;
		description: string | null;
		revision: string;
	};

	interface ProjectProps {
		project: project;
	}

	let { project }: ProjectProps = $props();
</script>

<div class="project">
	<h3 class="project__header">
		{project.name} <span class="project__header__id">#{project.id}</span>
	</h3>
	<nav class="project__actions" aria-label="Project actions">
		<Icon icon="more_vert" size="1.5rem" />
	</nav>
	<p class="project__description">
		{#if project.description}
			{project.description.length > 159
				? project.description.slice(0, 159) + '...'
				: project.description}
		{:else}
			No description available.
		{/if}
	</p>
	<span class="project__revision">Revision: {project.revision}</span>
</div>

<style lang="scss">
	.project {
		display: grid;
		grid-template:
			'header actions'
			'desc desc'
			'revision revision';
		grid-template-columns: 1fr auto;
		grid-template-rows: auto 1fr auto;
		max-width: 250px;
		width: 250px;
		height: 300px;
		border-radius: 5px;
		background-color: white;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
		padding: 1rem;
		padding-bottom: 0.5rem;

		&__actions {
			grid-area: actions;
			width: min-content;
			height: min-content;
			cursor: pointer;
			height: 1.5rem;

			&:hover {
				color: var(--accent-color);
			}
		}

		&__header {
			grid-area: header;
			font-weight: bold;
			margin: 0;
			font-size: 1.5rem;
			line-height: 1.5rem;
			overflow-x: hidden;
			height: max-content;

			&__id {
				font-size: 1rem;
				color: var(--secondary-font-color);
			}
		}
		&__description {
			grid-area: desc;
			font-size: 1rem;
			max-width: 99%;
			margin-top: 0.5rem;
			margin-bottom: 0;
			align-self: start;
			justify-self: start;
		}
		&__revision {
			grid-area: revision;
			font-size: 0.9rem;
			color: var(--secondary-font-color);
			align-self: end;
			justify-self: end;
		}
	}
</style>
