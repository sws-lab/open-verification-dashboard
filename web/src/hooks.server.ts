import type { ServerInit } from '@sveltejs/kit';
import findRemoveSync from 'find-remove';

function cleanupOldFiles() {
	console.log('Cleaning up old project files...');
	findRemoveSync('./projects', { extensions: ['.json'], maxLevel: 1, age: { seconds: 60 * 10 } });
}

export const init: ServerInit = () => {
	console.log('Server initialized, setting up cleanup task for old project files.');
	setInterval(
		() => {
			cleanupOldFiles();
		},
		1000 * 60 * 10 // every 10 minutes
	);
	cleanupOldFiles();
};
