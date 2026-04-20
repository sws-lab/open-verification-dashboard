<script>
	import '@fontsource-variable/manrope';
	import '@fontsource-variable/material-symbols-rounded';
	import '../global.scss';
	import { page } from '$app/state';

	let { children } = $props();
</script>

<header>
	<h1>Dashboard</h1>
	<ul>
		<li>
			<a href="/" class:active={page.url.pathname === '/'} aria-current={page.url.pathname === '/'}
				>Home</a
			>
		</li>
		<li>
			<a
				href="/projects"
				class:active={page.url.pathname === '/projects'}
				aria-current={page.url.pathname === '/projects'}>Projects</a
			>
		</li>
	</ul>
</header>
{@render children()}

<style lang="scss">
	header {
		display: flex;
		justify-content: start;
		align-items: center;
		background-color: #333;
		border-bottom: 2px solid var(--primary-color);
		box-shadow: 0 3px 5px rgb(0, 0, 0, 0.3);
		position: relative;
		z-index: 100;
		height: var(--header-height);
		padding: 0 1rem;

		h1 {
			width: fit-content;
			color: white;
			margin: 0;
			padding: 0;
		}

		ul {
			display: flex;
			list-style: none;
			margin: 0;
			margin-left: 2rem;
			padding: 0;
			gap: 1rem;
			li {
				a {
					color: white;
					text-decoration: none;
					transition: color 0.3s ease;
					font-size: 1.2rem;

					&.active {
						text-decoration: underline;
						text-decoration-color: var(--primary-color);
					}

					&:hover {
						color: var(--primary-color);
						transform: scale(10);
					}
				}
			}
		}
	}
</style>
