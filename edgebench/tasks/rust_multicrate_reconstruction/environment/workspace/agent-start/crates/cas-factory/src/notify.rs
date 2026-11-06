//! Unix datagram notification socket for instant prompt queue wakeup.
//!
//! The factory daemon binds a `DaemonNotifier` that listens for single-byte
//! datagrams. Workers call `notify_daemon()` after enqueuing a prompt to wake
//! the daemon immediately instead of waiting for the next poll interval.

use std::os::unix::net::UnixDatagram as StdUnixDatagram;
use std::path::{Path, PathBuf};
use tokio::net::UnixDatagram;

/// Returns the canonical path for the notification socket.
pub fn notify_socket_path(cas_dir: &Path) -> PathBuf { todo!() }

/// Daemon-side notification receiver.
///
/// Binds a Unix datagram socket and waits for notification bytes from workers.
/// Used in a `tokio::select!` branch to wake the event loop instantly when
/// new prompts are enqueued.
pub struct DaemonNotifier {
    socket: UnixDatagram,
    path: PathBuf,
}

impl DaemonNotifier {
    /// Bind the notification socket at `{cas_dir}/notify.sock`.
    ///
    /// Removes a stale socket file from a previous run if one exists.
    pub fn bind(cas_dir: &Path) -> std::io::Result<Self> { todo!() }

    /// Async wait for a notification byte. Cancellation-safe (tokio
    /// `UnixDatagram::recv` is cancellation-safe).
    pub async fn recv(&self) -> std::io::Result<()> { todo!() }

    /// Non-blocking drain of all pending datagrams to coalesce multiple
    /// notifications into a single wakeup.
    pub fn drain(&self) { todo!() }

    /// Remove the socket file (called on shutdown).
    pub fn cleanup(&self) { todo!() }
}

impl Drop for DaemonNotifier {
    fn drop(&mut self) { todo!() }
}

/// Fire-and-forget notification to the daemon.
///
/// Sends a single byte to `{cas_dir}/notify.sock`. This is synchronous and
/// non-blocking: if the socket buffer is full or the daemon is not listening,
/// it silently returns `Ok(())`.
pub fn notify_daemon(cas_dir: &Path) -> std::io::Result<()> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn bind_creates_socket_file() {
        let dir = TempDir::new().unwrap();
        let notifier = DaemonNotifier::bind(dir.path()).unwrap();
        assert!(notify_socket_path(dir.path()).exists());
        drop(notifier);
    }

    #[tokio::test]
    async fn notify_and_recv_round_trip() {
        let dir = TempDir::new().unwrap();
        let notifier = DaemonNotifier::bind(dir.path()).unwrap();

        // Send a notification from the "worker" side
        notify_daemon(dir.path()).unwrap();

        // Receive it on the daemon side (should complete immediately)
        let result =
            tokio::time::timeout(std::time::Duration::from_millis(100), notifier.recv()).await;
        assert!(result.is_ok(), "recv should complete within timeout");
        assert!(result.unwrap().is_ok());
    }

    #[tokio::test]
    async fn notify_when_no_listener_is_noop() {
        let dir = TempDir::new().unwrap();
        // No DaemonNotifier bound — notify_daemon should not error
        let result = notify_daemon(dir.path());
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn drain_clears_pending_notifications() {
        let dir = TempDir::new().unwrap();
        let notifier = DaemonNotifier::bind(dir.path()).unwrap();

        // Send multiple notifications
        for _ in 0..5 {
            notify_daemon(dir.path()).unwrap();
        }

        // Small delay so datagrams land
        tokio::time::sleep(std::time::Duration::from_millis(10)).await;

        // Drain should clear all pending
        notifier.drain();

        // After drain, recv should block (no data pending)
        let result =
            tokio::time::timeout(std::time::Duration::from_millis(50), notifier.recv()).await;
        assert!(result.is_err(), "recv should timeout after drain");
    }

    #[tokio::test]
    async fn cleanup_removes_socket_file() {
        let dir = TempDir::new().unwrap();
        let notifier = DaemonNotifier::bind(dir.path()).unwrap();
        let path = notify_socket_path(dir.path());
        assert!(path.exists());
        notifier.cleanup();
        assert!(!path.exists());
    }

    #[tokio::test]
    async fn stale_socket_is_removed_on_bind() {
        let dir = TempDir::new().unwrap();
        let path = notify_socket_path(dir.path());

        // Create a stale socket file (simulate previous crash)
        let _first = DaemonNotifier::bind(dir.path()).unwrap();
        assert!(path.exists());
        // Leak the first notifier (don't drop/cleanup) by forgetting it
        std::mem::forget(_first);
        assert!(path.exists());

        // Second bind should succeed by removing the stale socket
        let _second = DaemonNotifier::bind(dir.path()).unwrap();
        assert!(path.exists());
    }
}
