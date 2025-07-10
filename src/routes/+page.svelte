<script>
	import Accent from "$components/ui/accent.svelte";

</script>
<section>
	<p class="capitalize">
		Welcome to the <Accent>dashboard</Accent> app!
	</p>
	<p>
		I don't know what to say so just click on the beautiful call to action just under this text.
	</p>
	
	<a href="/projects">
		Browse projects
	</a>
</section>

<style lang="scss">
	section {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 1rem;
		padding: 2rem;

		.capitalize {
			font-size: 1.5rem;
			text-align: center;
			text-transform: capitalize;
		}

		a {
			border: 2px solid var(--accent-color);
			background-color: var(--accent-color);
			border-radius: 0.5rem;
			padding: 0.5rem 1rem;
			text-decoration: none;
			cursor: pointer;
			color: white;
			font-weight: 600;
			transition: transform 0.2s ease-in-out;
			font-size: 1.2rem;
			&:hover {
				transform: scale(1.05);
			}
		}
	}
</style>

