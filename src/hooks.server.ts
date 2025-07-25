import type { ServerInit } from '@sveltejs/kit';
import findRemoveSync from 'find-remove';

export const init: ServerInit = () => {
	console.log('Server initialized, setting up cleanup task for old project files.');
	setInterval(
		() => {
			console.log('Cleaning up old project files...');
			findRemoveSync('./projects/', { age: { seconds: 1000 * 60 * 10 }, extensions: ['.json'] });
		},
		1000 * 60 * 10
	);
	findRemoveSync('./projects/', { age: { seconds: 1000 * 60 * 10 }, extensions: ['.json'] });
};
