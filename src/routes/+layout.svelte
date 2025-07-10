<script>
	import "@fontsource-variable/manrope";
	import { Header } from "$components";
	import "../global.scss";
	let { children } = $props();
</script>
<Header/>
{@render children()}
