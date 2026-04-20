<script lang="ts">
	import { page } from '$app/state';
	import { Icon } from '.';
	interface PageSelectorProps {
		currentPage: number;
		totalPages: number;
		maxVisiblePages?: number;
		href: string;
		params?: Record<string, string>;
		label: string;
	}

	let {
		currentPage,
		totalPages,
		maxVisiblePages = 5,
		href,
		label,
		params = {}
	}: PageSelectorProps = $props();

	let minVisible = $derived(
		Math.max(
			2,
			Math.min(
				totalPages - maxVisiblePages + 2,
				currentPage - Math.floor((maxVisiblePages - 2) / 2)
			)
		)
	);
	let maxVisible = $derived(
		Math.min(
			totalPages - 1,
			Math.max(maxVisiblePages - 1, currentPage + Math.floor((maxVisiblePages - 2) / 2))
		)
	);
	let visibleCount = $derived(maxVisible - minVisible + 1);

	function buildUrl(page_id: number): string {
		const url = new URL(href, page.url.origin);
		url.searchParams.set('page', String(page_id));
		for (const [key, value] of Object.entries(params)) {
			url.searchParams.set(key, value);
		}
		return url.toString();
	}
</script>

{#snippet pageLink(page: number)}
	<li>
		<a
			href={buildUrl(page)}
			class:active={currentPage === page}
			aria-current={currentPage === page ? 'page' : undefined}
			aria-label={currentPage === page ? `Current page ${page}` : `Go to page ${page}`}
			rel={currentPage === page ? 'nofollow' : undefined}
		>
			{page}
		</a>
	</li>
{/snippet}

<nav class="page-selector" aria-label="{label}, page {currentPage} of {totalPages}">
	<ul>
		{#if currentPage > 1}
			<li class="prev">
				<a href={buildUrl(currentPage - 1)} aria-label="Previous page" rel="prev">
					<Icon icon="navigate_before" />
				</a>
			</li>
		{/if}

		{#if totalPages >= 1}
			{@render pageLink(1)}
		{/if}

		{#if currentPage > maxVisiblePages - 2}
			<li class="ellipsis" aria-hidden="true">
				<Icon icon="more_horiz" />
			</li>
		{/if}

		{#each { length: visibleCount }, index}
			{@render pageLink(index + minVisible)}
		{/each}

		{#if maxVisible < totalPages - 1}
			<li class="ellipsis" aria-hidden="true">
				<Icon icon="more_horiz" />
			</li>
		{/if}

		{#if totalPages > 1}
			{@render pageLink(totalPages)}
		{/if}

		{#if currentPage < totalPages}
			<li class="next">
				<a href={buildUrl(currentPage + 1)} aria-label="Next page" rel="next">
					<Icon icon="navigate_next" />
				</a>
			</li>
		{/if}
	</ul>
</nav>

<style lang="scss">
	.page-selector {
		display: flex;
		justify-content: center;
		padding: 1rem 0;

		ul {
			list-style: none;
			display: flex;
			gap: 0.5rem;
			margin: 0;
			padding: 0.5rem 0.75rem;

			li {
				&.ellipsis,
				&.next,
				&.prev {
					display: flex;
					align-items: center;
					justify-content: center;

					a {
						padding: 0;
					}
				}

				a {
					text-decoration: none;
					padding: 0.5rem 0.75rem;
					border: 1px solid transparent;
					border-radius: 4px;
					color: var(--text-color);
					background-color: var(--background-color);
					transition: background-color 0.2s;
					display: flex;
					align-items: center;
					justify-content: center;

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
