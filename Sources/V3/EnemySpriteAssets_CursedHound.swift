import Foundation
import SpriteKit
import UIKit

enum EnemySpriteAssets {

    static let graveSkeletonIdleFrames: [SKTexture] =
        makeFrames(
            base64: graveSkeletonIdleSheet,
            frameCount: 8
        )

    static let graveSkeletonHitFrames: [SKTexture] =
        makeFrames(
            base64: graveSkeletonHitSheet,
            frameCount: 2
        )

    static let graveSkeletonDeathFrames: [SKTexture] =
        makeFrames(
            base64: graveSkeletonDeathSheet,
            frameCount: 14
        )


    static let cursedHoundIdleFrames: [SKTexture] =
        makeFrames(
            base64: cursedHoundIdleSheet,
            frameCount: 6
        )

    static let cursedHoundWalkFrames: [SKTexture] =
        makeFrames(
            base64: cursedHoundWalkSheet,
            frameCount: 12
        )

    static let cursedHoundRunFrames: [SKTexture] =
        makeFrames(
            base64: cursedHoundRunSheet,
            frameCount: 5
        )

    static let cursedHoundJumpFrames: [SKTexture] =
        makeFrames(
            base64: cursedHoundJumpSheet,
            frameCount: 6
        )

    private static func makeFrames(
        base64: String,
        frameCount: Int
    ) -> [SKTexture] {
        guard
            let data = Data(base64Encoded: base64),
            let image = UIImage(data: data)
        else {
            return []
        }

        let sheet = SKTexture(image: image)
        sheet.filteringMode = .nearest

        let frameWidth =
            1.0 / CGFloat(frameCount)

        return (0..<frameCount).map { index in
            let texture =
                SKTexture(
                    rect:
                        CGRect(
                            x:
                                CGFloat(index)
                                * frameWidth,
                            y: 0,
                            width: frameWidth,
                            height: 1
                        ),
                    in: sheet
                )

            texture.filteringMode = .nearest

            return texture
        }
    }

    private static let graveSkeletonIdleSheet = """
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
"""

    private static let graveSkeletonHitSheet = """
iVBORw0KGgoAAAANSUhEUgAAAMYAAAAuCAYAAABzjGayAAAAAXNSR0IArs4c6QAAA/xJREFUeJzt3E9oHGUcxvHvpBXMQbqwLAvGdlso2EPAPxSkh5ScRGyLQiiRnoJ4yMGeDORYclBYiAdpFMEaAkoxB0GJK+JFL6U9tJqg1sQK280uhm26mvVPg5h2POy+09nJbrKbbnbm3T4fCMy+Mxnefd959jfvZAmIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIhItDlhd6Ddfs5MuWa7mM0y+PrbXfceo2q1VAw2uYHXNXORiCd3vU871TUXzbdTb7jJQ4c2tSscneMLRjAQft5cRDkYPWF3oB38oYgdTHk/xqfjw1tNlLTXdmNtxVx0RTCMUyPnGRgcY2BwbNM+hSNSIj8X1gfDVItTI+cBmOjrZaKvl4HBMYrZbNjde9hE/oJvlvXBMOZmztZtL+ULjE/PMz49r6oRLZGei71hd2CnRvr7awY2djDF3MxZr3JcOHey5viJvt7OdrCLNfH0yXpWPq0JhmI8PQrVcACs3cxRzGa9apF+9WkAhtKzVr7fqAkEY6ehcPRUqo2CoaD6SJZqIEwoAMan5zvfwYdL11UKw6pbqaNPPOkCvJB+C4Cl5QIAM+++51UN/4L7wrmTlPKVYyZ/+DeMLnezrg0FNlaMYCgA1p8/wfHRKY6PTnltpXyB0+kM1xZueaE49uLLXT2Zlon0XFhVMQgEAuD6jRwAKbcyzqfTGQDeP/MUAN/07Ot4H8V+1lQMcxs19+Y7m/Z9d2XF2zYBGb24AMBK4f6+y19+psV3e7Tj0z7Sc2FNMPxMOK7fyHmhKB94DoD+2COc2He/EP7zR5mVwopCES2RnwvrbqWMjz+6sqkt5zj0A0dSLuT2kilvQDUcIq2wsmKsNXjA1LMnRqa8wWKu8oFkbqv+Lt3uZPekC1gXjEah+PO3X7ztTHmDH9f+A184RFphza3U1cKSYxbgQR+cSQAJhicv0bMnxr27a+Qch5Tr8tPvpc531jJ1vuKxHSfqj1sfVKiLoNVS0f11OQ/AsWeONtWXw4lKOL5OPw7A8p1na/a/NvEF5UcrpwreQq3fuR35RV8YqsHwX+jNjtODhCPSXwkJ7UJZLRVdABMMgMMH9nvbiXjSufz9VdffnognHfN7f33+inesCYf5K/dQetZJ7D/iKhjNMWO6hXoVotmq0ei4SAcj9DWGPwz+kPgny7T72x576RMAbi7dqjnftYXK69X8okLQPvUu7FaqhXVzEVowEvGkN1iNwtGo3TChuJf/iuHJSwylZ50PF9e9/aoQTduNcQqe06q5CL1iGK2EIxFPOol40hm+eHfb8yocu85p4aK3Zi5C76i5PTLrh2Ao/JVFdked/+7RcF3Q6rmjvI7Yyv889XWL3HXjHAAAAABJRU5ErkJggg==
"""

    private static let graveSkeletonDeathSheet = """
iVBORw0KGgoAAAANSUhEUgAABWoAAAAuCAYAAACxvyCvAAAAAXNSR0IArs4c6QAAE8hJREFUeJzt3X9s3PV9x/HXhUTB/IqR47kkcRxrKSbF5deiEYYSPJBWOie00polUG3yUFA96giJmLiDdZbXEmRINkEMpCPKIrVLE1oklnAlIDFMo4ogAY0JaZI2zHZskjmJi90WUhTguz/s95fPff093/fOZ1/u7vmQTpy/Pofvfd73/d7d6/v5IQEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAlInlegcA4Hz0XMsqL7jtb9p3cc4EAAAAAACTYlqudwBA+jo71o0JEZF9LdsOqGXbAf/nsPAWAAAAAAAgG+gdBuSRw/GOhKBwoLtbg3399PTMMgtk3ZBWkra2LtfLL7ytDXtfpb0nib3GF9U30cYAAAAAgKLCF2EgjyQLasWw/KyxkLascp7fthoNbbe2Lqe9J0lnxzqvoro6YdtAd7fqmjbRzgAAAACAosAXYCAPWIhVuqDK3zbU05sQ1IrwMCuiTitBgJg9bkhrr/Ghnl6JsBYAAAAAUESm53oHAKRmIdbSuuaE7Vtbl6uscp7WtL0gjfYGJazNXDAwdNt7z/a1GujuzuHeFb4VDZslSfs6N6p0QZUf1vK6BgAAAAAUAxYTA/KAGxC2zS1R29wS/2frUetuw8RYSOu2demCKlVUV/s3ZIeF4xbSts0tGXNBAgAAAACAYkBQi6w6HO/w7BZ1CDlSc4OsMO13X6cLv1IzpftUiJIFsG1zSzTU05sw9QSya8/2tf59C2uDU3sAAAAAAFDICGqRFZ0d67zgQlcV1dWR5/tEctaGFmTd8PAatb5/NuExLdsO5GbnCtRQT6/2dW5U6/tn/ZsNxR/o7tai+iaG4WdZ6YIq7dm+1m9vW7itZdsBtWw74C/yBgAAAABAoSKoxYQF5/W0myFgmZi6pk0xm/rA5u7c17nRD27dkJZ5PCfGDWCHenr9Nt6zfa0/Xyomj4W1W1uXJ2xnWg8AAAAAQDEoqMXE3B6drBQ+9dyh+fs6Nyb8jsWAssMNCy28tVDr5Rfeztl+FZJF9U0xu/gw0N3th7XW3pxXsquuaVPscLzDs9e2tbP1pm2/+7oc7yEAAAAAAFOjIIJat0ensWH3hCqTK2whIElaWtc8plccMlfXtClmUyAEX+uDff30pM0y97xh7c65ZPK5i+YFp/PgNQ4AAAAAKHR5/8U3OOze2FyShFiTy23/FQ2b/aA2OMekRhe8ohbZcTje4bk9D2lXFILgnNa2kBivbwAAAABAMSiIHrVi2H3O2dySVgfmmJxci+qbYg21tZ4kHZ2/UIvn1XiS9Gb/UV7nyFvWc9wC2re6TmnD3ld5TQMAAAAAikJefwFONuzeenOKHllTwuYGth7Nbm9md45JapA9bkjrOvfOYcJaAAAAAACAPDQt1zuQDbbYT5AFhS3bDui5llVe6IMwYTYEf6in1w9pFTLHJLLDQlpJqjl+bMzvrXctAAAAAAAA8kdBBLU27L71/bMJvWkNw+4nT0Ntrbd9y0v+z+5iQFtbl/u9aTce/Dgn+1dogiFsfPiTSI9DZhbPq/HcW673BwAAAAAAFK68HiLdUFvrtbQ3Sgy7n1I747tHht0fH5lWovvJpyRJ7w6d08bvfD7lROOOLt1z9RV6ddos/29f/9nz1GECLCysLZ2RENJefPlIG3/4wbCqvJE8kSkQMmftPOOaRdLolBKGdkUhsalr7CJbXdMmXt8AAAAAkCN526PWhn8z7H5qBUNaSTr7V/WKD3+i3lhMK9vjWtke93/nhrTInmBP2g8/GNaHHwznbH8KSTCkTfZ7IN9ZSCtJFdXV0ujim7ncJwAAAAAoZnnXcyasN6f1qnWH3ctZSGzjwY/pyZklbU8/lfAl/le/6ZUkvffs8/623tjnTX3x5bN0xbwrJHrTTpgFhNa+VZ7n36+fNd0Pb+lRmzl3/t+whdqCaGPkKzekDRuRIkaiAAAAAMCUy6setcl6cy5r7NCyxg5/22Bfv1a2x/VW1yl/btSb/vrr9BLKgtZ/vHfMF/e395/079eWzlD9rOn+zx9+MKyT/ScJaSfIAvLeWExVnueHsfWzpmvdNRf4993wFtlzsv8k7YqC0dmxLiGkXVrXHPo4etcCAAAAwNTKq6D26PH+hJDWenNacMWw+6mx5+HHpdH2t5B2eP6N/u+vqvLGhLXInIW0Kx66T7eu/FpCW0vSkd6RAPHdoXN+kCtJJRfNJmTJUHz4Ex07eETHDh7Ryf6TvIZRkFY0bNbSuma1zS3R0rrmhPndmT4IAAAAAKZeXgW1qXpzWkDVuKNLGu0FZ+jRmR02/P5HP9yf0PYa7e0ZH/7EDw6tHn8YPJOLXS0IO+O7vZr588ZsH55/o4bn36j48Cf+zXp89sZi6o3FdEnZbJVcNNuzWw52vyAQ0qIQrWjYLElqm1vi/3dN2wsqq5znL8KJ/GMjj5Bb1OH8QB3OD9QBAPIT5+/cyavw0kLCFQ/dl9CbU5JmHX9DtaUzpMBCSxdfPks977yRV8/zfGY1CPbqlKTfnfi1Pvt0SHJCWkk69NtBSdLZj85QhzSFTffxox/uT3jM70782r9v7W+CITk1SK2httYLLtZWP2u63h06J0ka+lgqnTmy/dBvB/02tTCcNs5MskXamAc4+zo71nm2eJgFtpK0tXW536PWwtoo89TaeWp1/R3UKoeoQ+bcOZsHurtV17Qp4zbcGd/tUQPko2weB0A+4bx9fqEegDQ9wmPOO8GgSqO9CGtHh92r9/OFlegNNzUsLJx2Qak++3TIH4JvIS0yFzbdRzLW/uaSstkJYW3JRbM9gsTkFs+r8dxF2WpLZ4ycU+RJmqF3h86pdOZIWGuCvZXdn2nraBbPq/FmXLNIClm0bfG8Gs8Na4NXdvkgl7nSBVXas32tShdU+QuJTWTKAz5YZyYYjvzTz97LaBQQbZ8+96KFqaiuVmfHOo86TK2wkNDWl2BU3OQa7ziwsJZaTI5M3jepxfmDWkyOTN5HU9WCz6hTh+MiO/Kq8aL05rS5UW2+zj8MniEsyaJkNXjmrnJJ0qqNv5Ccnp1uSEgdJu6Lf/H3/hcZa/N7dpxO6FWrQM9aetWmp7zyKs96hFsvfQV66svpNW7nmTC0dWpuSGuCYa1Ge9aGDb/hQ1f63C/lbkjrGuwbuUAUpUet+ACckbBwRBMMaxEu7PUZPA6MHQ+Dff3aePBj6pBlwZ7fqY4DQx2yx61B1OPARS2yI9n75ng9m4OLYxNKTY4ovcuj1II6TEzUXv5RjwtkjlpMvbxquGQhoYVUyYbdE5Ykd3pwwDt2vE+SdNP1i1O2k9Vg6GPp5fY5kqTjH92Q8Jg1bS9o+MKRf4qgdqx029z1v9v+0lOSNv/9xZdLo8eB27PWakD7p7bq/hbvvWefT9hmc//K6bE864+e/xoPor2js/NJMKgNLuAWvAC3ecujWl1/R2xnfLf3DyvvHvPv0vbRuF/Q3aB2sK9fb3Wd0jOHPp9eKFiD031HaOMUxvuCFiUcWfdiz7jHATVIT7AeVgN3+o99nRsTaiCJOmSRe7Et3ZAw1fsCdYgmWVCe6jhww9pktbi9fYPWNq6nFhka76JFsGezCavF7e0btPFbD3BcZCBKDUyUWohzVEbSqYOoxaSiFrmTV4uJJbOr+Wbtar5Z0y4olZxghWH34zs9OJB4xeOXb3qnBwf8m21zt7/ZfzT2YtfP9fqRn/t/N/+it/37g339/tyGLCI2ViZtbn/n/m2yNjduj9qzH52JEVyl1vb0U96XvlilP/3br/uLtQ3Pv1GllX+uaReU+ueXaReU+qF4mEvKZuuSstkqr7yKydcjqjl+zL8f9oY+Mv3E5+f2tY3rVXLR7NCQttjtjO/2ok78H/YBywLCYEgbrEHw9e0uXMgChtGtaNispXXNWlrXPOZ3m766wL8fpQYYn13c2Rnf7QXDqba5JWqbW6Kldc1jepenOh9Rh/QFL2CMdxw0f3lm0veF29s3qPkHj0nUIbLxLlaMdxyY8d6jDbVIX/Cihd3Mcy2rPEX8vLS35UHOTxmIWgOT7mdXahFNunUQtZg01CK3chrUnh4c8CyUivJ4d57Cl9b06aU1ff7wb40GtrP+OPJPEdJGt3B+pX/fenoqECradnfbpV/bKUnqOXoq4d97qyvxZ8MX989NRptfNudKDfTsj1mgiOjann4q4bV5w5IrQh9nF4U0GtjS1hNn00scO3hExw4eSXhDt9ERR3pj/tQT1u6X/clCyQnG3Vt55VVeMb/xpzPMblF9U6y9ZYu2b3lJK9vjatzRFbkGFQuW+G2crA7prBZbaCvLpupNGzUciVKDqEF5lCC/0Opgwp7Xnu1rQx9ri+q1bDugLXddKzl1WHDvI7q9fYOU5FjIxn4VqtX1d8SS9eSMGpa7x8PaxvVSoA5cLEoteG6Kchw0f3lmyvfotY3rqcUEjXfRwkKRdD8vUYv0RKlBQ20ttZhkUeogajElqEVu5KyXnYVPbkjlhlflZRUxC3Bte3lZRcz+7vf/vdp/rA0Dt+E5jTu6mJczorBgUOMEie52STr46K3+/Tt3XZow7P5035FY8GCjDtlt81vbD4W2pxtSMaQg9XQTO+O7veCibW/vH+lR+NKakb8bb4qPhP8X7e1L1e6v//JN7wd/15CwzYbCuFPY9MZiSUNxt/e4JG3e8qg02us2Si0Kcf6wKO1u2+1DlWuiNUjYl74jsShtXEx1cHsorGjYrLa5JZKk1vfPamvrcj8ckaT2u6/TI/81cj9qDZh+JZHVoffECX/bF7pfU0V1tT9Hs4WFW1uXS05A1Ta3RBd+pcavgfXelKT7vr1hzP/LrUOxnn/G4x4TH//ix0rnOGjc0ZXROSmdtSqKqR6nBwe8Qz9+NK3jYE/80ITeH9JdN6RY6hF20ULOsSDnO+6e+CH/76ayFoUu0xoYapEdYVOxmGAd5qx+QMHvEKIWWUMtci/nQa0yDKs0Gtb2HD2laZW3S868ehv2vkpAGFFwKH7UWpSXVcQkaWF5jfcfd4/MNWJBrZwvKNRhrIm2uST9T8vVniIEtYSGmV0Uanr439Tx0P1SiotC9+7q9S9KRN2fQv7i4c59l0m7P3DLbXrstVf0petu0RttI72a3YDcFisMct/YLaiN2saFVo+JtPsDt9ymf7l/ZJSK2+737Djt3w8uXGjCwtpiPv8E6zCRkLCscp7+r/oWSdJ3H/5pWjUQdUh6PJzZ/xPJmRvVnZOzZdsBf0qh62tOJRwPVouwoFYhdeDLxohgLSyojXocXF8zMpIoeG6KejwU83EQ5Nai9MR+KcJxsCd+SI+99oq+eu0yPfuvY9eooBaZcQNzRbxoQS2yL90LqMvWPyE5n5+oRXYE6+AKq8Oc1Q+M+SxLLbKDWuRezqY+cEOnKOGsu93Y8O/P+vZqZXtc9+7q1Ya9rxZtMTPh1qG8rCIW1ublZRWxm65f7N/cvzl2+mjs1vZDsVU7Pg39ksiXk7Em2uYaDWiThbQaPanZiS2dOSsLgT3f4HNOZ7oJC2mVYrqJgZ79sc1bHk1r6KrNk5ju8zrfJXtO47W7/c62P/baK5KkXx14zX+cOx/zruabdemHH+iyOVcm3Q8bChtVIYW0rkza3f6rQLs/c1e5vN+8IUm6bM6V/g2phV1ktqBvqKdXpQuqtK9zoz/02A1HLJyyx0vS9x76BjXIQO+JE35Ybq97G14/1NPrh1OS/C8eLvd4+EL3a/rnhgeoQ4bsmJh5851SxOPAQhGFnJvsPSFVHYp9SpwwC+dXRj4O7P3hxa7wNSrSqQVDW8OVLqjSnu1r1fr+2YSenMbCQ2oxeaLWIPj5iVpkl9XBBOvgohaTi1rkTk6/oE60Z2F55VXerrsukEaDq4oFS7yBnv3+c3IL+58/2VawX8jPB6l6cFotzn50JtIwWGRPcIXfQpYsLLxtyY3+/YlON/GtfX8mjQYmQcXQxskEV/NWFkZOhI2akKTv7JspOTW479sbEno2F9NrPsxkt3uQXRX/7NMhbd7yaNG2e5Bbh1f2vzHm99fquH/fwpE1bS9Io70TJOncsm+O+bvvPvzTMdvcGvj//yLuheAKvi9UzRnp3bFwfqXfqzY4J6q95petfyL0eHDr4tYjrA6m2OuxM77bC74Xu9MfaJzjwILa8c5N9n7g9jqnDmPZZ3D3/JTqOHB7Spmo7xPUIrXTgwNe1B7+1GLyHI53eIpYA0Mtsi9qHUQtJh21yK2cLiaWjZ6Fq3Z86g//dkNa0ZvzvHL2ozMxQtrccBfvCCqk3rbjPQ83JEmnB395WUWsvKzC7718atkj+t5D3wgNabMlX+uR6rjOZOREsBeznMUK3Ro8/uSDY0La4P1M5Vs9dsZ3e5m+3s147R7GroaH1cDdr3xry0zYcww+VzegMl2aLwXCke9vf0zf3/6Yzi37ZmhI+87mfw/9/ybrkZCs3Qu9HuM9N7dn7ewlKzV7yUr/d4N9/Zp58516q+uUHw4Gj4ewupgovWuT7Vsh1iN4PATPTdarVoHjYGvr8jEhrdI4N4XVwR1pFLaPUbfns2TPafaSlRqas8T/ebCvX1ffuV5vdZ3yv3xn8j5hIwAmc9/zUdhzSaeHf6bv2Y8/+eDEdrzABOsQtQbZ+Px02ZwrqUcSUeuwbP0TWasFwlELAAAAAAAAAEBR+38GiUUFSu8ELgAAAABJRU5ErkJggg==
"""
}
