import * as tar from 'tar';
import type { ArchiveManager } from './archivesManager';

export const tarManager: ArchiveManager = {
	async extractFile(file: File, destination: string): Promise<void> {
		const p = tar.x({ C: destination }).on('error', (err) => {
			console.error('Error extracting project files:', err);
			throw new Error('Failed to extract project files.');
		});
		p.write(await file.bytes());
		p.end();
	},
	async getUnzippedSize(file: File): Promise<number> {
		let unzippedSize = 0;
		const p = tar
			.list()
			.on('entry', (entry: File) => {
				unzippedSize += entry.size;
			})
			.on('error', (err: Error) => {
				console.error('Error reading tar file:', err);
				throw new Error('Failed to read project file.');
			})
			.on('end', () => {
				console.log(`Total unzipped size: ${unzippedSize} bytes`);
			});
		p.write(await file.bytes());
		p.end();
		return unzippedSize;
	}
};
