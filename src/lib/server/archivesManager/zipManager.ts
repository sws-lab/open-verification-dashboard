import unzipper from 'unzipper';

export const zipManager: ArchiveManager = {
	async extractFile(file: File, destination: string): Promise<void> {
		return new Promise((resolve, reject) => {
			const stream = unzipper.Extract({ path: destination })
				.on('error', (err) => {
					console.error("Error extracting project files:", err);
					reject(new Error("Failed to extract project files."));
				})
				.on('close', () => {
					console.log(`Project files extracted to: ${destination}`);
					resolve();
				});
			file.bytes().then((data) => {
				stream.write(data);
				stream.end();
			}).catch((err) => {
				console.error("Error reading file bytes:", err);
				reject(new Error("Failed to read project file bytes."));
			});
		});
	},
	async getUnzippedSize(file: File): Promise<number> {
		return new Promise((resolve, reject) => {
			let unzippedSize = 0;
			const stream = unzipper.Parse()
				.on('entry', (entry) => {
					unzippedSize += entry.vars.uncompressedSize;
					entry.autodrain();
				})
				.on('error', (err: Error) => {
					console.error("Error reading zip file:", err);
					reject(new Error("Failed to read project file."));
				})
				.on('end', () => {
					console.log(`Total unzipped size: ${unzippedSize} bytes`);
					resolve(unzippedSize);
				});
			file.bytes().then((data) => {
				stream.write(data);
				stream.end();
			}).catch((err) => {
				console.error("Error reading file bytes:", err);
				reject(new Error("Failed to read project file bytes."));
			});
		});
	}
};