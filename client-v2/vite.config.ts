import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		fs: {
			// Allow serving files from the wasm directory
			allow: ['..']
		}
	},
	resolve: {
		alias: {
			'$wasm': path.resolve(__dirname, '../wasm/pkg')
		}
	},
	optimizeDeps: {
		exclude: ['caps-wasm']
	}
});
