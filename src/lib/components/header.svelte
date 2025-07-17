<header>
	<h1><a href="/">Dashboard</a></h1>
</header>

<style lang="scss">
	header {
		display: flex;
		justify-content: start;
		align-items: center;
		background-color: #333;
		border-bottom: 2px solid var(--accent-color);
		box-shadow: 0 3px 5px rgb(0, 0, 0, 0.3);
		position: relative;
		z-index: 100;
		height: var(--header-height);
		padding: 0 3rem;

		h1 {
			width: fit-content;
			a {
				color: white;
				text-decoration: none;
				transition: color 0.3s ease;

				&:hover {
					color: var(--accent-color);
					transform: scale(10);
				}
			}
		}
	}
</style>