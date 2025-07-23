<script lang="ts">
	import { Dropdown, DropdownItem } from '$ui';
	import type { ElementClicked } from './ui/dropdown/dropdown.svelte';
	import Icon from './ui/icon.svelte';
	type project = {
		id: number;
		name: string;
		description: string | null;
		revision: number;
	};

	interface ProjectProps {
		project: project;
		onaction?: (action: string, id: number) => void;
	}

	let { project, onaction }: ProjectProps = $props();

	let menu: typeof Dropdown | undefined = $state();

	function elementClicked(event: ElementClicked) {
		if (event.elementName == null) return;
		onaction?.(event.elementName, project.id);
	}
</script>

<div class="project">
	<h3 class="project__header">
		<a href={`/projects/${project.id}/${project.revision}/project`}>
			{project.name} <span class="project__header__id">#{project.id}</span>
		</a>
	</h3>
	<nav class="project__actions" aria-label="Project actions">
		<button onclick={menu?.show} aria-haspopup="true" aria-expanded="false" aria-controls="+li">
			<Icon icon="more_vert" size="1.5rem" />
		</button>
		<Dropdown bind:this={menu} {elementClicked}>
			<DropdownItem name="edit" href={`/projects/${project.id}/${project.revision}/project`}>
				<Icon icon="edit_document" /> Edit
			</DropdownItem>
			<DropdownItem name="settings" href={`/projects/${project.id}/${project.revision}/settings`}>
				<Icon icon="settings" /> Settings
			</DropdownItem>
			<DropdownItem name="delete" type="risky">
				<Icon icon="delete" />
				Delete
			</DropdownItem>
		</Dropdown>
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
			height: 1.5em;
			button {
				cursor: pointer;
				height: 1.5rem;
				margin: 0;
				padding: 0rem;

				border: none;
				background: transparent;

				&:hover {
					color: var(--accent-color);
				}
			}
		}

		&__header {
			grid-area: header;
			font-weight: bold;
			margin: 0;
			font-size: 1.5rem;
			line-height: 1.5rem;
			overflow: hidden;
			height: max-content;

			a {
				text-decoration: none;
				color: var(--primary-font-color);
				word-break: break-all;
				&:hover {
					color: var(--accent-color);
				}
			}

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
			text-overflow: ellipsis;
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
