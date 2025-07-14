<script lang="ts">
	import { page } from "$app/state";
	import { Icon } from ".";
	interface PageSelectorProps {
		currentPage: number;
		totalPages: number;
		maxVisiblePages?: number;
		href: string;
		params?: Record<string, string>;
	}

	let { currentPage, totalPages, maxVisiblePages = 5, href, params = {} }: PageSelectorProps = $props();

	function buildUrl(page_id: number): string {
		const url = new URL(href, page.url.origin);
		url.searchParams.set("page", String(page_id));
		for (const [key, value] of Object.entries(params)) {
			url.searchParams.set(key, value);
		}
		return url.toString();
	}
</script>

<nav class="page-selector" aria-label="Page navigation">
	<ul>
		{#if currentPage > 1}
			<li>
				<a href="{buildUrl(currentPage - 1)}" aria-label="Previous page">
					<Icon icon="navigate_before"/>
				</a>
			</li>

		{/if}

		{#each {length: Math.min(totalPages, maxVisiblePages)}, index}
			<li>
				<a href="{buildUrl(index + 1)}" class:active="{currentPage === index + 1}" aria-current="{currentPage === index + 1 ? 'page' : undefined}">
					{index + 1}
				</a>
			</li>
		{/each}
			

		{#if currentPage < totalPages}
			<li>
				<a href="{buildUrl(currentPage + 1)}" aria-label="Next page">
					<Icon icon="navigate_next"/>
				</a>
			</li>
		{/if}
	</ul>
</nav>

<style lang="scss">
.page-selector {
	display: flex;
	justify-content: center;
	margin: 1rem 0;

	ul {
		list-style: none;
		display: flex;
		gap: 0.5rem;

		li {
			a {
				text-decoration: none;
				padding: 0.5rem 0.75rem;
				border: 1px solid transparent;
				border-radius: 4px;
				color: var(--text-color);
				background-color: var(--background-color);
				transition: background-color 0.2s;

				&:hover {
					background-color: var(--hover-background-color);
				}

				&.active {
					background-color: var(--active-background-color);
					border-color: var(--active-border-color);
					font-weight: bold;
				}
			}
		}
	}
}
</style>