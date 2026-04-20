type FileContent =
	| {
			type: 'file';
			content: string;
	  }
	| {
			type: 'error';
			content: string;
	  }
	| {
			type: 'directory';
			content: Record<string, FileContent>;
	  };

export default async function loadProjectFile(
	id: number,
	revision: number,
	path: string
): Promise<FileContent> {
	console.log('Selected file:', path);
	return await fetch(`/api/projects/${id}/${revision}/${path}`)
		.then((response) => response.json())
		.then((content: FileContent) => {
			console.log('File content loaded', content);
			return content;
		})
		.catch((error) => {
			console.error('Error loading file:', error);
			return { type: 'error', content: 'Error loading file content.' };
		});
}
