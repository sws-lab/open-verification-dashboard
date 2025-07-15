<script lang="ts">
	let { children, data } = $props();
	import { page } from "$app/state";

	const tabs = [
		{ name: "code", label: "Code" },
		{ name: "proofObligations", label: "Proof Obligations" },
		{ name: "settings", label: "Settings" }
	];

	let currentTab = $derived.by(() => {
		const path = page.url.pathname.split("/");
		return path[path.length - 1];
	})	
</script>

{#snippet tabLink(page: string, label: string = page)}
	<a 
		href={`/projects/${data.project.id}/${data.revision}/${page}`} 
		class:active={currentTab === page}
		aria-current={currentTab === page ? "page" : undefined}
		aria-label={label}
		data-sveltekit-keepfocus
	>
		{label}
	</a>
{/snippet}

<div>
	<h2>{data.project.name} <span>#{data.project.id}</span></h2>

	<nav>
		<ul>
			{#each tabs as tab}
				<li>
					{@render tabLink(tab.name, tab.label)}
				</li>
			{/each}
		</ul>
	</nav>
</div>
<section>
	{@render children()}
</section>

<style lang="scss">
	:global(body) {
		height: 100vh;
		max-height: 100vh;
	}

	div {
		background-color: white;
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
			span {
				font-size: 1.27rem;
				color: var(--color-secondary-text);
			}
		}


		nav {
			align-self: end;
			margin-right: 1rem;
			ul, li {
				list-style: none;
				margin: 0;
				padding: 0;
				background: red;
			}
			ul {
				display: flex;
				gap: 1rem;
			}
		}
	}

	section {
		max-height: calc(100vh - calc(var(--tools-height) + var(--header-height)));
		height: 100%;
		width: 100vw;
	}
</style>