<script lang="ts">
	let { children, data } = $props();
	import { page } from '$app/state';

	const tabs = [
		{ name: 'project', label: 'Project' },
		{ name: 'proofObligations', label: 'Proof Obligations' },
		{ name: 'settings', label: 'Settings' }
	];

	let currentTab = $derived.by(() => {
		const path = page.url.pathname.split('/');
		return path[path.length - 1];
	});
</script>

{#snippet tabLink(page: string, label: string = page)}
	<li class:active={currentTab === page}>
		<a
			href={`/projects/${data.project.id}/${data.project.revision}/${page}`}
			aria-current={currentTab === page ? 'page' : undefined}
			aria-selected={currentTab === page}
			aria-label={label}
			aria-controls={currentTab === page ? 'layout-content' : ''}
			role="tab"
			data-sveltekit-keepfocus
		>
			{label}
		</a>
	</li>
{/snippet}

<div>
	<h2>{data.project.name} <span>#{data.project.id}</span></h2>

	<nav>
		<ul role="tablist">
			{#each tabs as tab (tab.name)}
				{@render tabLink(tab.name, tab.label)}
			{/each}
		</ul>
	</nav>
</div>
<section id="layout-content">
	{@render children()}
</section>

<style lang="scss">
	div {
		background-color: white;
		padding: 0 1rem;
		font-size: 1.5rem;
		z-index: 101;
		position: relative;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
		height: var(--tools-height);
		display: flex;
		align-items: center;
		justify-content: space-between;

		h2 {
			margin: 0;
			color: var(--primary-color);
			span {
				font-size: 1rem;
				color: var(--secondary-font-color);
			}
		}

		nav {
			align-self: end;
			margin-right: 1rem;
			ul,
			li {
				list-style: none;
				margin: 0;
				padding: 0;
			}
			ul {
				display: flex;
				gap: 1rem;
			}

			li {
				padding: 0.5rem 1rem;
				border-radius: 0.25rem 0.25rem 0 0;

				&.active {
					border: 1px solid rgba(0, 0, 0, 0.1);
					border-bottom: none;
					background-color: rgba(0, 0, 0, 0.1);
				}

				a {
					text-decoration: none;
					color: inherit;
				}
			}
		}
	}

	section {
		height: calc(100vh - calc(var(--tools-height) + var(--header-height)));
		padding: 1px; // disable margin collapse
		width: 100vw;
	}
</style>
