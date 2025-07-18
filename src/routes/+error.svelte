<script lang="ts">
	import { page } from '$app/state';
</script>

<section>
	<h2>
		{page.status}
	</h2>
	<p>
		{page.error?.message || 'An unexpected error occurred.'}
	</p>
	<p>
		Back to <a href="/">home</a>.
	</p>
</section>

<style lang="scss">
	section {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 100%;
		width: 100%;

		h2 {
			font-size: 8rem;
			color: var(--color-error);
			margin-bottom: 0;
		}

		p {
			margin: 0;
			font-size: 2rem;
		}
	}
</style>
