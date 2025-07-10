<script>
	import "@fontsource-variable/manrope";
	import "@fontsource-variable/material-symbols-rounded";
	import { Header } from "$components";
	import "../global.scss";
	let { children } = $props();
</script>
<Header/>
{@render children()}
