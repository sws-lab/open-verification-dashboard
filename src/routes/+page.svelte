<script>
	import { Button } from "$ui";
	import Accent from "$components/ui/accent.svelte";

</script>
<section>
	<p class="capitalize">
		Welcome to the <Accent>dashboard</Accent> app!
	</p>
	<p>
		I don't know what to say so just click on the beautiful call to action just under this text.
	</p>
	
	<Button href="/projects">
		Browse projects
	</Button>
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
	}
</style>

