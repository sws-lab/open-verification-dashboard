<script lang="ts">
	let { searchQuery = $bindable(''), onsearch, delay = 300, maxLength = 40 } = $props();

	let searchTimeout: NodeJS.Timeout | null = null;

	function search() {
		if (searchQuery.length > maxLength) {
			searchQuery = searchQuery.slice(0, maxLength);
		}
		if (searchTimeout) {
			clearTimeout(searchTimeout);
		}
		searchTimeout = setTimeout(() => {
			onsearch(searchQuery);
		}, delay);
	}
</script>

<nav class="search" role="search" aria-label="Filter list by name">
	<input
		type="text"
		placeholder="Filter"
		bind:value={searchQuery}
		oninput={search}
		role="searchbox"
	/>
</nav>

<style lang="scss">
	@use '$styles/mixins.scss' as *;

	.search {
		display: flex;
		align-items: center;
		padding: 0.3rem 0.6rem;
		border: 1px solid #ccc;
		border-radius: 4px;
		width: 100%;
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
</style>
