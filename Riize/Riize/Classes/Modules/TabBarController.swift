import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBarAppearance()
    }
    
    private func setupViewControllers() {
        let homeVC = UIViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "home_n_2025_6_13")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "home_s_2025_6_13")?.withRenderingMode(.alwaysOriginal)
        )
        
        let likeVC = UIViewController()
        likeVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "like_n_2025_6_13")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "like_s_2025_6_13")?.withRenderingMode(.alwaysOriginal)
        )
        
        let messageVC = UIViewController()
        messageVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "message_n_2025_6_13")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "message_s_2025_6_13")?.withRenderingMode(.alwaysOriginal)
        )
        
        let meVC = UIViewController()
        meVC.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "me_n_2025_6_13")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "me_s_2025_6_13")?.withRenderingMode(.alwaysOriginal)
        )
        
        let navigationControllers = [
            UINavigationController(rootViewController: homeVC),
            UINavigationController(rootViewController: likeVC),
            UINavigationController(rootViewController: messageVC),
            UINavigationController(rootViewController: meVC)
        ]
        
        setViewControllers(navigationControllers, animated: false)
    }
    
    private func setupTabBarAppearance() {
        // 设置TabBar背景色为白色
        tabBar.backgroundColor = .white
        
        // 设置TabBar背景图片
        if let tabBarBackgroundImage = createTabBarBackgroundImage() {
            tabBar.backgroundImage = tabBarBackgroundImage
        }
        
        // 移除TabBar顶部线条
        tabBar.shadowImage = UIImage()
    }
    
    private func createTabBarBackgroundImage() -> UIImage? {
        let size = CGSize(width: UIScreen.main.bounds.width, height: tabBar.frame.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
} 