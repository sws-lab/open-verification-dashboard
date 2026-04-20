/**
 * @filename: lint-staged.config.js
 * @type {import('lint-staged').Configuration}
 */
export default {
	'*.{js,ts,svelte,scss,json}': ['prettier --write', 'eslint --fix']
};
