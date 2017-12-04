import UIKit

enum PhotoType: Int {
    case interesting = 0
    case recent = 1
}

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var photoType: PhotoType!
    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()
    
    // MARK: - View cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchPhoto(ofType: photoType)
    }
    
    // MARK: - Setup
    
    func setupTabBarItem() {
    
        let tabBarSystemItem: UITabBarSystemItem
        switch photoType! {
        case PhotoType.interesting:
            tabBarSystemItem = UITabBarSystemItem.featured
        case PhotoType.recent:
            tabBarSystemItem = UITabBarSystemItem.recents
        }
        
        tabBarItem = UITabBarItem(tabBarSystemItem: tabBarSystemItem, tag: photoType!.rawValue)
    }
    
    // MARK: - Fetch Photo
    
    func fetchPhoto(ofType photoType: PhotoType) {
        
        /// download the image data for the first photo that is returned from the interesting photos request and display it on the image view
        store.fetchPhotos(ofType: photoType) {
            (photosResult) in
            
            switch photosResult {
            case let .success(photos):
                print("Successfully found \(photos.count) photos")
                self.photoDataSource.photos = photos
            case let .failure(error):
                print("Error fetching interesting photos: \(error)")
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = photoDataSource.photos[indexPath.row]
        
        // Download the image data, which could take some time
        store.fetchImage(for: photo) { (imageResult) in
            
            // The index path for the photo might have changed between the
            // time the request started and finished, so find the most
            // recent index path
            
            guard let photoIndex = self.photoDataSource.photos.index(of: photo),
            case let .success(image) = imageResult
                else {
                    return
            }
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            // When the request finishes, only update the cell if it's still visible
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(with: image)
            }
        }
    }
}
