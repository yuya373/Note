//
//  Either.swift
//  Note
//
//  Created by 南優也 on 2018/03/20.
//  Copyright © 2018年 南優也. All rights reserved.
//

import Foundation

enum Either<L, R> {
    case Left(L)
    case Right(R)
}
