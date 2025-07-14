type ArchiveManager = {
	extractFile(file: File, destination: string): Promise<void>;
	getUnzippedSize(file: File): Promise<number>;
}
